defmodule Edgybot.Workers.DiscordMesssageEventWorker do
  @moduledoc false
  use Oban.Worker,
    queue: :message_event,
    max_attempts: 1,
    tags: ["discord", "message"]

  alias Edgybot.Bot.Plugin.AIPlugin
  alias Nostrum.Struct.Message

  @impl Worker
  def perform(%Oban.Job{args: %{"message" => message}}) do
    message
    |> Message.to_struct()
    |> AIPlugin.handle_message()

    :ok
  end
end
