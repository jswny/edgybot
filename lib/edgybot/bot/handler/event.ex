defmodule Edgybot.Bot.Handler.Event do
  def handle_event(event, payload) do
    case event do
      :MESSAGE_CREATE ->
        message = payload
        handle_message_create(message)

      _ ->
        :noop
    end
  end

  defp handle_message_create(message) when is_struct(message) do
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
