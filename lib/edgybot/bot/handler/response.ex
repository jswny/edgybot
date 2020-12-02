defmodule Edgybot.Bot.Handler.Response do
  @moduledoc false

  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @color_red 16_734_003

  def handle_response(:noop, _source), do: :noop

  def handle_response({:error, reason} = response, %{channel_id: channel_id})
      when is_binary(reason) and is_integer(channel_id) do
    embed = build_error_embed(response)
    new_response = {:message, channel_id, embed: embed}
    send_response(new_response)
  end

  def handle_response({:message, content}, %{channel_id: channel_id})
      when is_binary(content) and is_integer(channel_id) do
    response = {:message, channel_id, content}
    send_response(response)
  end

  defp send_response(response) when is_tuple(response) do
    case response do
      {:message, channel_id, content_or_opts} ->
        Api.create_message!(channel_id, content_or_opts)
    end
  end

  defp build_error_embed({:error, reason}) do
    %Embed{}
    |> Embed.put_title("Error")
    |> Embed.put_color(@color_red)
    |> Embed.put_field("Reason", reason)
  end
end
