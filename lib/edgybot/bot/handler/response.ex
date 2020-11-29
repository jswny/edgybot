defmodule Edgybot.Bot.Handler.Response do
  alias Nostrum.Api

  def handle_response(:noop, _source), do: :noop

  def handle_response({:error, reason}, %{channel_id: channel_id}) do
    reason = "`Error: #{reason}`"
    response = {:message, channel_id, reason}
    send_response(response)
  end

  def handle_response({:message, content}, %{channel_id: channel_id}) do
    response = {:message, channel_id, content}
    send_response(response)
  end

  def send_response(response) do
    case response do
      {:message, channel_id, content} -> Api.create_message!(channel_id, content)
      _ -> :noop
    end
  end
end
