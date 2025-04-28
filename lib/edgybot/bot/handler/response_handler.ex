defmodule Edgybot.Bot.Handler.ResponseHandler do
  @moduledoc false

  import Bitwise

  alias Edgybot.Bot.Designer
  alias Edgybot.Bot.Utils
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Interaction

  @interaction_channel_message_with_source 4
  @interaction_deferred_channel_message_with_source 5

  def defer_response(%Interaction{} = interaction, ephemeral?) do
    %{}
    |> add_response_metadata(@interaction_deferred_channel_message_with_source, ephemeral?)
    |> send_direct_response(interaction)
  end

  def send_immediate_response(response, %Interaction{} = interaction, ephemeral?) do
    response
    |> create_response_object()
    |> add_response_metadata(@interaction_channel_message_with_source, ephemeral?)
    |> send_direct_response(interaction)
  end

  def send_followup_response(response, %Interaction{} = interaction, ephemeral?) do
    response_object =
      response
      |> create_response_object()
      |> add_response_metadata(@interaction_channel_message_with_source, ephemeral?)

    Api.edit_interaction_response(interaction, response_object.data)
  end

  defp send_direct_response(response_object, %Interaction{} = interaction),
    do: Api.create_interaction_response(interaction, response_object)

  defp add_response_metadata(response_object, response_type, ephemeral?) when is_boolean(ephemeral?) do
    response_object = Map.put(response_object, :type, response_type)

    if ephemeral? do
      update_in(response_object, [:data], fn
        nil -> %{flags: 1 <<< 6}
        data -> Map.put(data, :flags, 1 <<< 6)
      end)
    else
      response_object
    end
  end

  defp create_response_object({"message", message}) when is_binary(message), do: %{data: %{content: message}}

  defp create_response_object({type, message}) when type in ["success", "warning", "error"] and is_binary(message) do
    options = %{"description" => message}
    create_response_object(type, options)
  end

  defp create_response_object({type, options}) when type in ["success", "warning", "error"] and is_map(options),
    do: create_response_object(type, options)

  defp create_response_object(type, options) when type in ["success", "warning", "error"] and is_map(options) do
    {response_data, options} = transform_image(%{}, options)

    case_result =
      case type do
        "success" -> Designer.success_embed(options)
        "warning" -> Designer.warning_embed(options)
        "error" -> Designer.error_embed(options)
      end

    embed = maybe_truncate_embed(case_result)

    response_data =
      Map.update(response_data, :embeds, [embed], fn embeds_list ->
        Enum.map([embed | embeds_list], &maybe_truncate_embed/1)
      end)

    %{data: response_data}
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

  defp transform_image(response_object, %{"image" => image} = options) when is_map(response_object) and is_map(options) do
    case image do
      {"file", image_data} ->
        filename = "image-#{Utils.random_string(8)}.png"
        file = %{body: image_data, name: filename}

        new_response_object =
          Map.update(response_object, :files, [file], fn files_list ->
            [file | files_list]
          end)

        new_options = Map.put(options, "image", "attachment://#{filename}")

        {new_response_object, new_options}

      _ ->
        {response_object, options}
    end
  end

  defp transform_image(response_object, options) when is_map(response_object) and is_map(options),
    do: {response_object, options}
end
