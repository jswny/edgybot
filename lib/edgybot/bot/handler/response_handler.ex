defmodule Edgybot.Bot.Handler.ResponseHandler do
  @moduledoc false

  use Bitwise
  alias Edgybot.Bot.Designer
  alias Nostrum.Api

  @interaction_deferred_channel_message_with_source 5

  def defer_interaction_response(%{id: id, token: token} = interaction)
      when is_integer(id) and
             is_binary(token) do
    response = Map.put(Map.new(), :type, @interaction_deferred_channel_message_with_source)

    {:ok} = Api.create_interaction_response(interaction, response)
    interaction
  end

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
    response = data

    {:ok, _message} = Api.edit_interaction_response(interaction, response)
  end
end
