defmodule Edgybot.Bot.Handler.Event do
  @moduledoc false

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
    if Handler.Command.is_command?(message) do
      Handler.Command.handle_command(message)
    else
      :noop
    end
  end
end
