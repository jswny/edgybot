defmodule Edgybot.Bot.Handler.Event do
  @moduledoc false

  alias Edgybot.Bot.Handler

  def handle_event(event, payload) when is_atom(event) do
    case event do
      :MESSAGE_CREATE ->
        message = payload

        if message.author.bot != true do
          handle_message_create(message)
        else
          :noop
        end

      _ ->
        :noop
    end
  end

  defp handle_message_create(message) when is_map(message) do
    if Handler.Command.is_command?(message.content) do
      Handler.Command.handle_command(message.content)
    else
      :noop
    end
  end
end
