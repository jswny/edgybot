defmodule Edgybot.Workers.DiscordChannelIndexWorker do
  alias Edgybot.Config
  alias Edgybot.External.{Discord, OpenAI, Qdrant}

  alias Nostrum.Api
  require Logger

  use Oban.Worker,
    queue: :index_discord_channel,
    tags: ["discord"]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "guild_id" => guild_id,
          "channel_id" => channel_id,
          "message_id" => message_id
        }
      }) do
    Logger.debug(
      "Indexing from message #{message_id} in channel #{channel_id} in guild #{guild_id}"
    )

    batch_size = Config.index_discord_message_batch_size()
    embedding_model = Config.openai_embedding_model()
    points_collection = Config.qdrant_collection_discord_messages()

    {:ok, messages} = Api.get_channel_messages(channel_id, batch_size, {:before, message_id})

    messages
    |> Enum.filter(&Discord.valid_text_message?/1)
    |> Enum.map(&build_point_input(&1, guild_id))
    |> Enum.chunk_every(batch_size)
    |> Enum.each(&embed_and_save_point_input_batch(&1, points_collection, embedding_model))

    last_message = List.last(messages) || %{id: message_id}
    last_message_id = Map.get(last_message, :id)

    if last_message_id == message_id do
      Logger.debug(
        "Finished indexing channel #{channel_id} in guild #{guild_id}, last message: #{message_id}"
      )
    else
      %{guild_id: guild_id, channel_id: channel_id, message_id: last_message_id}
      |> new()
      |> Oban.insert()
    end

    :ok
  end

  defp build_point_input(
         %{
           id: id,
           channel_id: channel_id,
           author: %{id: user_id},
           timestamp: timestamp,
           content: content
         },
         guild_id
       )
       when is_integer(guild_id) do
    unix_timestamp = DateTime.to_unix(timestamp, :millisecond)

    %{
      id: id,
      payload: %{
        guild_id: guild_id,
        user_id: user_id,
        channel_id: channel_id,
        timestamp: unix_timestamp,
        content: content
      }
    }
  end

  defp embed_and_save_point_input_batch(point_input_batch, points_collection, embedding_model)
       when is_list(point_input_batch) and is_binary(points_collection) and
              is_binary(embedding_model) do
    embedding_inputs =
      Enum.map(point_input_batch, fn %{payload: %{content: embedding_input}} ->
        embedding_input
      end)

    body = %{input: embedding_inputs, model: embedding_model}

    case OpenAI.post_and_handle_errors("v1/embeddings", body) do
      {:ok, embedding_response} ->
        points =
          embedding_response
          |> Map.fetch!("data")
          |> Enum.zip(point_input_batch)
          |> Enum.map(fn {%{"embedding" => embedding}, point} ->
            Map.put(point, :vector, embedding)
          end)

        {:ok, %{status: 200}} =
          Qdrant.call(:put, "/collections/#{points_collection}/points", %{points: points})
    end
  end
end
