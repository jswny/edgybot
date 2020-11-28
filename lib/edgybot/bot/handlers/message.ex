defmodule Edgybot.Bot.Handlers.Message do
  @moduledoc false

  def handle_message_create(message) when is_struct(message) do
    ping = "ping"

    case message.content do
      ^ping ->
        {:response, "Pong!"}

      _ ->
        :ignore
    end
  end
end
