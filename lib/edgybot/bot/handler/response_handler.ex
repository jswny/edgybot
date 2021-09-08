defmodule Edgybot.Bot.Handler.ResponseHandler do
  @moduledoc false

  use Bitwise
  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Nostrum.Api

  @interaction_message_response 4

  def handle_response(:noop, _source), do: :noop

  def handle_response({type, message}, %{id: id, token: token} = interaction)
      when is_atom(type) and type in [:success, :warning, :error] and is_binary(message) and
             is_integer(id) and
             is_binary(token) do
    options = [description: message]
    handle_embed_response(type, options, interaction)
  end

  def handle_response({type, options}, %{id: id, token: token} = interaction)
      when is_atom(type) and type in [:success, :warning, :error] and is_list(options) and
             is_integer(id) and
             is_binary(token) do
    handle_embed_response(type, options, interaction)
  end

  defp handle_embed_response(type, options, %{id: id, token: token} = interaction)
       when is_atom(type) and type in [:success, :warning, :error] and is_list(options) and
              is_integer(id) and
              is_binary(token) do
    embed =
      case type do
        :success -> Designer.success_embed(options)
        :warning -> Designer.warning_embed(options)
        :error -> Designer.error_embed(options)
      end

    response_data = %{embeds: [embed]}
    send_interaction_response(interaction, response_data)
  end

  defp send_interaction_response(%{id: id, token: token} = interaction, data)
       when is_integer(id) and is_binary(token) and is_map(data) do
    data = maybe_silence_response(data)

    response =
      Map.new()
      |> Map.put(:type, @interaction_message_response)
      |> Map.put(:data, data)

    {:ok} = Api.create_interaction_response(interaction, response)
  end

  defp maybe_silence_response(data) when is_map(data) do
    silent_mode = Config.silent_mode()

    if silent_mode do
      Map.put(data, :flags, 1 <<< 6)
    else
      data
    end
  end
end
