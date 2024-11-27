defmodule Edgybot.Bot.Handler.InteractionHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Config
  alias Edgybot.Bot.Handler.{MiddlewareHandler, ResponseHandler}
  alias Edgybot.Bot.Plugin
  alias Edgybot.Bot.Registrar.PluginRegistrar

  alias Nostrum.Struct.{
    ApplicationCommandInteractionData,
    ApplicationCommandInteractionDataOption,
    ApplicationCommandInteractionDataResolved,
    Interaction
  }

  @default_metadata []

  defguardp valid_resolved_data(resolved_data)
            when is_struct(resolved_data, ApplicationCommandInteractionDataResolved) or
                   is_nil(resolved_data)

  def handle_interaction(
        %Interaction{data: %{name: interaction_name, type: interaction_type}} = interaction
      )
      when is_binary(interaction_name) and is_integer(interaction_type) do
    application_command_prefix = Config.application_command_prefix()

    interaction_name =
      if application_command_prefix,
        do: String.replace_prefix(interaction_name, "#{application_command_prefix}", ""),
        else: interaction_name

    log_prefix = "Handling interaction #{interaction_name}"

    interaction = put_in(interaction.data.name, interaction_name)

    log_prefix =
      if application_command_prefix,
        do: "#{log_prefix} with prefix #{application_command_prefix}",
        else: log_prefix

    Logger.debug("#{log_prefix} (type: #{interaction_type})...")

    handle_interaction_transformed(interaction)
  end

  def handle_interaction_transformed(
        %Interaction{data: %{name: interaction_name, type: interaction_type}} = interaction
      )
      when is_binary(interaction_name) and is_integer(interaction_type) do
    matching_plugin_module = PluginRegistrar.get_module({interaction_name, interaction_type})

    case matching_plugin_module do
      nil ->
        :noop

      _ ->
        {application_command_name_list, application_command_type, options} =
          parse_interaction(interaction)

        application_command_metadata =
          get_application_command_metadata_for_interaction(
            interaction,
            matching_plugin_module,
            application_command_name_list
          )

        middleware_data =
          interaction
          |> defer_interaction_response(application_command_metadata, options)
          |> process_middleware_for_interaction(matching_plugin_module)

        matching_plugin_module.handle_interaction(
          application_command_name_list,
          application_command_type,
          options,
          interaction,
          middleware_data
        )
    end
  end

  defp build_application_command_metadata(
         %{name: name, children: children} = parent_meatadata_tree_node,
         [interaction_name_head | interaction_name_rest],
         current_metadata
       )
       when is_binary(name) and is_list(children) and is_binary(interaction_name_head) and
              is_list(interaction_name_rest) and is_map(current_metadata) do
    parent_current_metadata =
      merge_metadata_heirarchy(parent_meatadata_tree_node, current_metadata)

    if name == interaction_name_head do
      children
      |> Enum.map(fn metadata_tree_node ->
        new_current_metadata =
          merge_metadata_heirarchy(metadata_tree_node, parent_current_metadata)

        build_application_command_metadata(
          metadata_tree_node,
          interaction_name_rest,
          new_current_metadata
        )
      end)
      |> Enum.find(%{}, &(!is_nil(&1)))
    else
      nil
    end
  end

  defp build_application_command_metadata(
         %{name: name} = metadata_tree_node,
         [interaction_name_head | _interaction_name_rest],
         current_metadata
       )
       when is_binary(name) and is_binary(interaction_name_head) and is_map(current_metadata) do
    if name == interaction_name_head do
      merge_metadata_heirarchy(metadata_tree_node, current_metadata)
    else
      nil
    end
  end

  defp build_application_command_metadata(%{}, _interaction_name_list, current_metadata)
       when is_map(current_metadata),
       do: current_metadata

  defp build_application_command_metadata(metadata_tree, interaction_name_list)
       when is_map(metadata_tree) and is_list(interaction_name_list) do
    build_application_command_metadata(metadata_tree, interaction_name_list, %{})
  end

  defp merge_metadata_heirarchy(metadata_tree_node, current_metadata)
       when is_map(metadata_tree_node) and is_map(current_metadata) do
    metadata_tree_node_metadata = Map.get(metadata_tree_node, :data, %{})
    Map.merge(current_metadata, metadata_tree_node_metadata)
  end

  defp get_application_command_metadata_for_interaction(
         %Interaction{data: %{name: interaction_name, type: interaction_type}},
         plugin_module,
         interaction_name_list
       )
       when is_binary(interaction_name) and is_integer(interaction_type) and
              is_atom(plugin_module) and is_list(interaction_name_list) do
    application_command_metadata_tree =
      plugin_module
      |> Plugin.get_definition_by_key(interaction_name, interaction_type)
      |> Map.get(:metadata, Map.new())

    build_application_command_metadata(
      application_command_metadata_tree,
      interaction_name_list
    )
  end

  defp defer_interaction_response(
         %Interaction{} = interaction,
         application_command_metadata,
         parsed_options
       ) do
    default_ephemeral? = Map.get(application_command_metadata, :ephemeral, false)
    ephemeral_option = Plugin.find_option_value(parsed_options, "hide")

    ephemeral? =
      if ephemeral_option != nil,
        do: ephemeral_option,
        else: default_ephemeral?

    ResponseHandler.defer_interaction_response(interaction, ephemeral?)
  end

  defp process_middleware_for_interaction(
         %Interaction{data: %{name: interaction_name, type: interaction_type}} = interaction,
         plugin_module
       )
       when is_binary(interaction_name) and is_integer(interaction_type) and
              is_atom(plugin_module) do
    middleware_list =
      plugin_module
      |> Plugin.get_definition_by_key(interaction_name, interaction_type)
      |> Map.get(:middleware, [])
      |> Enum.concat(@default_metadata)
      |> Enum.uniq()

    MiddlewareHandler.handle_middleware(middleware_list, interaction)
  end

  defp parse_interaction(%Interaction{
         data: %ApplicationCommandInteractionData{type: application_command_type} = data
       })
       when is_integer(application_command_type) do
    resolved_data = Map.get(data, :resolved)

    {parsed_application_command_name_list, parsed_options} =
      parse_interaction_data(data, resolved_data)

    {flatten_reverse(parsed_application_command_name_list), application_command_type,
     flatten_reverse(parsed_options)}
  end

  defp parse_interaction_data(
         %{name: application_command_name_part, options: options} = data_with_options,
         resolved_data
       )
       when is_binary(application_command_name_part) and is_list(options) and
              (is_struct(data_with_options, ApplicationCommandInteractionData) or
                 is_struct(data_with_options, ApplicationCommandInteractionDataOption)) and
              valid_resolved_data(resolved_data) do
    Enum.reduce(options, {[application_command_name_part], []}, fn option,
                                                                   {parsed_application_command_name_list,
                                                                    parsed_options} ->
      {parsed_application_command_name_part, parsed_option} =
        parse_interaction_data(option, resolved_data)

      {[parsed_application_command_name_part | parsed_application_command_name_list],
       [parsed_option | parsed_options]}
    end)
  end

  defp parse_interaction_data(
         %ApplicationCommandInteractionDataOption{
           name: option_name,
           type: option_type,
           value: option_value
         },
         resolved_data
       )
       when is_binary(option_name) and is_integer(option_type) and
              valid_resolved_data(resolved_data) do
    resolved_option_value = get_resolved_option_value(option_type, option_value, resolved_data)
    parsed_option = {option_name, option_type, resolved_option_value}
    {[], [parsed_option]}
  end

  defp parse_interaction_data(
         %ApplicationCommandInteractionData{name: parsed_application_command_name_part},
         _resolved_data
       )
       when is_binary(parsed_application_command_name_part) do
    {[parsed_application_command_name_part], []}
  end

  defp get_resolved_option_value(type, value, resolved_interaction_data)
       when is_integer(type) and type in [6, 7, 8, 11] and is_integer(value) and
              valid_resolved_data(resolved_interaction_data) do
    get_resolved_data_for_type(type, value, resolved_interaction_data)
  end

  defp get_resolved_option_value(type, value, resolved_interaction_data)
       when is_integer(type) and type == 9 and is_integer(value) and
              valid_resolved_data(resolved_interaction_data) do
    [6, 8]
    |> Enum.map(fn t ->
      try do
        get_resolved_data_for_type(t, value, resolved_interaction_data)
      rescue
        KeyError -> nil
      end
    end)
    |> Enum.find(&(&1 != nil))
  end

  defp get_resolved_option_value(_type, value, _resolved_interaction_data), do: value

  defp get_resolved_data_for_type(option_type, option_value, resolved_interaction_data)
       when is_integer(option_type) and option_type == 6 and is_integer(option_value) and
              valid_resolved_data(resolved_interaction_data) do
    user_data =
      resolved_interaction_data
      |> Map.fetch!(:users)
      |> Map.fetch!(option_value)

    member_data =
      resolved_interaction_data
      |> Map.fetch!(:members)
      |> Map.fetch!(option_value)

    Map.merge(user_data, member_data)
  end

  defp get_resolved_data_for_type(option_type, option_value, resolved_interaction_data)
       when is_integer(option_type) and option_type in [7, 8, 11] and is_integer(option_value) and
              valid_resolved_data(resolved_interaction_data) do
    resolved_interaction_data_field =
      case option_type do
        7 -> :channels
        8 -> :roles
        11 -> :attachments
      end

    resolved_interaction_data
    |> Map.fetch!(resolved_interaction_data_field)
    |> Map.fetch!(option_value)
  end

  defp flatten_reverse(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.reverse()
  end
end
