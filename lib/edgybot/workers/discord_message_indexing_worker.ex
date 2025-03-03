defmodule Edgybot.Workers.DiscordMessageIndexingWorker do
  @moduledoc false
  use Oban.Worker,
    queue: :discord_message_batch_index,
    tags: ["discord", "ai"],
    unique: [keys: [:guild_id, :channel_id, :batch_size, :latest_message_id]]

  alias Edgybot.External.Discord
  alias Edgybot.External.OpenAI
  alias Edgybot.External.Qdrant
  alias Nostrum.Struct.Message

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"guild_id" => guild_id, "channel_id" => channel_id, "messages" => messages}}) do
    latest_message_id = List.first(messages)["id"]

    Logger.debug(
      "Batch indexing messages in channel #{channel_id} in guild #{guild_id} from message: #{latest_message_id}"
    )

    embedding_model = Application.get_env(:edgybot, OpenAI)[:embedding_model]
    points_collection = Application.get_env(:edgybot, Qdrant)[:collection_discord_messages]

    messages
    |> Enum.map(fn message -> Message.to_struct(message) end)
    |> Enum.filter(&Discord.valid_text_message?/1)
    |> Enum.map(&build_point_input(&1, guild_id))
    |> embed_and_save_point_input_batch(points_collection, embedding_model)

    :ok
  end

  defp build_point_input(
         %{id: id, channel_id: channel_id, author: %{id: user_id}, timestamp: timestamp, content: content},
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
       when is_list(point_input_batch) and is_binary(points_collection) and is_binary(embedding_model) do
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
