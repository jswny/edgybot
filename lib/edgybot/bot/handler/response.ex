defmodule Edgybot.Bot.Handler.Response do
  @moduledoc false

  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @color_red 16_734_003

  def handle_response(:noop, _source), do: :noop

  def handle_response({:error, reason, error_source} = response, %{channel_id: channel_id})
      when is_binary(reason) and is_binary(error_source) and is_integer(channel_id) do
    embed = build_error_embed(response)
    new_response = {:message, channel_id, embed: embed}
    send_response(new_response)
  end

  def handle_response({:error, reason, error_source, stacktrace} = response, %{
        channel_id: channel_id
      })
      when is_binary(reason) and is_binary(error_source) and is_list(stacktrace) and
             is_integer(channel_id) do
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

    :noop
  end

  defp build_error_embed({:error, reason, error_source})
       when is_binary(reason) and is_binary(error_source),
       do: base_error_embed(reason, error_source)

  defp build_error_embed({:error, reason, error_source, stacktrace})
       when is_binary(reason) and is_list(stacktrace) do
    stacktrace = Exception.format_stacktrace(stacktrace)

    base_error_embed(reason, error_source)
    |> Embed.put_field("Stacktrace", code_block(stacktrace))
  end

  defp base_error_embed(reason, error_source)
       when is_binary(reason) and is_binary(error_source) do
    %Embed{}
    |> Embed.put_title("Error")
    |> Embed.put_color(@color_red)
    |> Embed.put_description(code_inline(reason))
    |> Embed.put_field("Source", error_source)
    |> Embed.put_timestamp(current_timestamp())
  end

  defp code_inline(content) when is_binary(content), do: "`#{content}`"

  defp code_block(content) when is_binary(content), do: "```#{content}```"

  defp current_timestamp do
    DateTime.utc_now()
    |> DateTime.to_string()
  end
end
