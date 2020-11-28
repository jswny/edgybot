defmodule Edgybot.Bot.Handlers.Message do
  @moduledoc false

  alias Nostrum.Api

  def handle_message_create(message) when is_struct(message) do
    ping = "ping"

    channel_id = message.channel_id

    case message.content do
      ^ping ->
        Api.create_message(channel_id, "Pong!")

      _ ->
        :ignore
    end
  end
end
