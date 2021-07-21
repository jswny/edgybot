defmodule Edgybot.Bot.Handler.ResponseHandler do
  @moduledoc false

  use Bitwise
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @color_red 16_734_003
  @interaction_message_response 4

  def handle_response(:noop, _source), do: :noop

  def handle_response({:message, content}, %{id: id, token: token} = interaction)
      when is_binary(content) and is_integer(id) and is_binary(token) do
    response_data = %{content: content}
    send_interaction_response(interaction, response_data)
  end

  def handle_response(
        {:error, reason} = response,
        %{id: id, token: token} = interaction
      )
      when is_binary(reason) and is_integer(id) and is_binary(token) do
    error_embed = build_error_embed(response)
    response_data = %{embeds: [error_embed]}
    send_interaction_response(interaction, response_data)
  end

  def handle_response(
        {:error, reason, stacktrace} = response,
        %{id: id, token: token} = interaction
      )
      when is_binary(reason) and is_list(stacktrace) and is_integer(id) and is_binary(token) do
    error_embed = build_error_embed(response)
    response_data = %{embeds: [error_embed]}
    send_interaction_response(interaction, response_data)
  end

  def send_interaction_response(%{id: id, token: token} = interaction, data)
      when is_integer(id) and is_binary(token) and is_map(data) do
    data = maybe_silence_response(data)

    response =
      Map.new()
      |> Map.put(:type, @interaction_message_response)
      |> Map.put(:data, data)

    Api.create_interaction_response(interaction, response)
  end

  defp build_error_embed({:error, reason})
       when is_binary(reason),
       do: base_error_embed(reason)

  defp build_error_embed({:error, reason, stacktrace})
       when is_binary(reason) and is_list(stacktrace) do
    stacktrace = Exception.format_stacktrace(stacktrace)

    base_error_embed(reason)
    |> Embed.put_field("Stacktrace", code_block(stacktrace))
  end

  defp base_error_embed(reason)
       when is_binary(reason) do
    %Embed{}
    |> Embed.put_title("Error")
    |> Embed.put_color(@color_red)
    |> Embed.put_description(code_block(reason))
    |> Embed.put_timestamp(current_timestamp())
  end

  defp code_block(content) when is_binary(content), do: "```#{content}```"

  defp current_timestamp do
    DateTime.utc_now()
    |> DateTime.to_string()
  end

  defp maybe_silence_response(data) when is_map(data) do
    silent_mode = Edgybot.silent_mode()

    if silent_mode do
      Map.put(data, :flags, 1 <<< 6)
    else
      data
    end
  end
end
