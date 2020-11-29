defmodule Edgybot.Bot.Handler.Response do
  alias Nostrum.Api

  def handle_response(response) do
    case response do
      {:response, channel_id, response} -> Api.create_message!(channel_id, response)
      _ -> :noop
    end
  end
end
