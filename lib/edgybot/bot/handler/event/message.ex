defmodule Edgybot.Bot.Handler.Event.Message do
  @moduledoc false

  def handle_message_create(message) when is_struct(message) do
    prefix = "/e"
    ping = "#{prefix} ping"

    case message.content do
      ^ping ->
        {:response, message.channel_id, "Pong!"}

      _ ->
        :noop
    end
  end
end
