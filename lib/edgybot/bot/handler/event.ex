defmodule Edgybot.Bot.Handler.Event do
  alias Edgybot.Bot.Handler

  def handle_event(event, payload) do
    case event do
      :MESSAGE_CREATE ->
        message = payload
        Handler.Message.handle_message_create(message)

      _ ->
        :noop
    end
  end
end
