defmodule Edgybot.Bot.Handler.ResponseHandler do
  @moduledoc false

  import Bitwise
  alias Edgybot.Bot.{Designer, Utils}
  alias Nostrum.Api
  alias Nostrum.Struct.{Embed, Interaction}

  @interaction_deferred_channel_message_with_source 5

  def defer_interaction_response(%Interaction{} = interaction, ephemeral?)
      when is_boolean(ephemeral?) do
    response = Map.put(Map.new(), :type, @interaction_deferred_channel_message_with_source)

    response =
      case ephemeral? do
        true -> Map.put(response, :data, %{flags: 1 <<< 6})
        false -> response
      end

    {:ok} = Api.create_interaction_response(interaction, response)
    interaction
  end

  def handle_response(:noop, _source), do: :noop

  def handle_response({:message, message}, %Interaction{} = interaction)
      when is_binary(message) do
    response_data = %{content: message}
    send_interaction_response(interaction, response_data)
  end

  def handle_response({type, message}, %Interaction{} = interaction)
      when is_atom(type) and type in [:success, :warning, :error] and is_binary(message) do
    options = [description: message]
    handle_embed_response(type, options, interaction)
  end

  def handle_response({type, options}, %Interaction{} = interaction)
      when is_atom(type) and type in [:success, :warning, :error] and is_list(options) do
    handle_embed_response(type, options, interaction)
  end

  defp handle_embed_response(type, options, %Interaction{} = interaction)
       when is_atom(type) and type in [:success, :warning, :error] and is_list(options) do
    {response_data, options} = transform_image(%{}, options)

    embed =
      case type do
        :success -> Designer.success_embed(options)
        :warning -> Designer.warning_embed(options)
        :error -> Designer.error_embed(options)
      end
      |> maybe_truncate_embed()

    response_data =
      Map.update(response_data, :embeds, [embed], fn embeds_list ->
        [embed | embeds_list]
        |> Enum.map(&maybe_truncate_embed/1)
      end)

    send_interaction_response(interaction, response_data)
  end

  defp maybe_truncate_embed(%Embed{description: nil} = embed), do: embed

  defp maybe_truncate_embed(%Embed{} = embed) do
    description = embed.description
    max_length = 4096

    description =
      if String.length(description) > max_length do
        truncated_indicator = "<truncated>"
        truncate_length = max_length - String.length(truncated_indicator) - 1

        truncated_description =
          description
          |> String.slice(0..truncate_length)
          |> Kernel.<>(truncated_indicator)

        truncated_description
      else
        description
      end

    Map.put(embed, :description, description)
  end

  defp transform_image(response_data, options) when is_map(response_data) and is_list(options) do
    if Keyword.has_key?(options, :image) do
      image = Keyword.get(options, :image)

      case image do
        {:file, image_data} ->
          filename = "image-#{Utils.random_string(8)}.png"
          file = %{body: image_data, name: filename}

          new_response_data =
            Map.update(response_data, :files, [file], fn files_list ->
              [file | files_list]
            end)

          new_options = Keyword.put(options, :image, "attachment://#{filename}")

          {new_response_data, new_options}

        _ ->
          {response_data, options}
      end
    else
      {response_data, options}
    end
  end

  defp send_interaction_response(%Interaction{} = interaction, data) when is_map(data) do
    response = data

    {:ok, _message} = Api.edit_interaction_response(interaction, response)
  end
end
