defmodule Edgybot.Bot.Handler.Event do
  alias Edgybot.Bot
  alias Edgybot.Bot.Handler

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
    cond do
      Handler.Command.is_command?(message) -> Handler.Command.handle_command(message)
      true -> :noop
    end
  end
end
