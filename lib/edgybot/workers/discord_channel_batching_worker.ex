defmodule Edgybot.Workers.DiscordChannelBatchingWorker do
  @moduledoc false
  use Oban.Worker,
    queue: :discord_channel_batch,
    tags: ["discord"],
    unique: [keys: [:guild_id, :channel_id, :batch_size, :latest_message_id]]

  alias Edgybot.Config
  alias Edgybot.Workers.DiscordMessageIndexingWorker
  alias Nostrum.Api

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"guild_id" => guild_id, "channel_id" => channel_id, "latest_message_id" => latest_message_id} = args
      }) do
    Logger.debug("Batching messages in channel #{channel_id} in guild #{guild_id} from message: #{latest_message_id}")

    batch_size = Config.discord_channel_message_batch_size()

    {:ok, messages} =
      Api.get_channel_messages(channel_id, batch_size, {:before, latest_message_id})

    batch_size_index = Config.discord_channel_message_batch_size_index()

    messages
    |> Enum.chunk_every(batch_size_index)
    |> Enum.each(fn message_batch ->
      args
      |> Map.put("batch_size", batch_size_index)
      |> Map.put("latest_message_id", List.first(message_batch).id)
      |> Map.put("messages", message_batch)
      |> DiscordMessageIndexingWorker.new()
      |> Oban.insert()
    end)

    earliest_message = List.last(messages) || %{id: latest_message_id}
    earliest_message_id = Map.get(earliest_message, :id)

    if earliest_message_id == latest_message_id do
      Logger.debug("Finished batching channel #{channel_id} in guild #{guild_id}, last message: #{earliest_message_id}")
    else
      %{
        guild_id: guild_id,
        channel_id: channel_id,
        batch_size: batch_size,
        latest_message_id: earliest_message_id
      }
      |> new()
      |> Oban.insert()
    end

    :ok
  end
end
