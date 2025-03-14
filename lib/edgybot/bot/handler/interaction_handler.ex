defmodule Edgybot.Bot.Handler.InteractionHandler do
  @moduledoc false

  alias Edgybot.Bot.Handler.MiddlewareHandler
  alias Edgybot.Bot.Plugin
  alias Edgybot.Bot.Registrar.PluginRegistrar
  alias Edgybot.Config

  require Logger

  @default_metadata []

  def transform_interaction_name(%{"data" => %{"name" => interaction_name, "type" => interaction_type}} = interaction)
      when is_binary(interaction_name) and is_integer(interaction_type) do
    application_command_prefix = Config.application_command_prefix()

    interaction_name =
      if application_command_prefix,
        do: String.replace_prefix(interaction_name, "#{application_command_prefix}", ""),
        else: interaction_name

    put_in(interaction, ["data", "name"], interaction_name)
  end

  def match_plugin_module(%{"data" => %{"name" => interaction_name, "type" => interaction_type}} = interaction)
      when is_binary(interaction_name) and is_integer(interaction_type) do
    matching_plugin_module = PluginRegistrar.get_module({interaction_name, interaction_type})

    case matching_plugin_module do
      nil ->
        {:error, "No matching plugin"}

      _ ->
        {:ok, interaction, matching_plugin_module}
    end
  end

  def get_application_command_metadata_for_interaction(
        %{"data" => %{"name" => interaction_name, "type" => interaction_type}},
        plugin_module,
        interaction_name_list
      )
      when is_binary(interaction_name) and is_integer(interaction_type) and is_atom(plugin_module) and
             is_list(interaction_name_list) do
    application_command_metadata_tree =
      plugin_module
      |> Plugin.get_definition_by_key(interaction_name, interaction_type)
      |> Map.get(:metadata, Map.new())

    build_application_command_metadata(
      application_command_metadata_tree,
      interaction_name_list
    )
  end

  def parse_interaction(%{"data" => data}) do
    resolved_data = Map.get(data, "resolved")

    {parsed_application_command_name_list, parsed_options} =
      parse_interaction_data(data, resolved_data)

    {flatten_reverse(parsed_application_command_name_list), parsed_options}
  end

  def ephemeral?(application_command_metadata, parsed_options) do
    default_ephemeral? = Map.get(application_command_metadata, :ephemeral, false)
    Map.get(parsed_options, "hide", default_ephemeral?)
  end

  def process_middleware_for_interaction(
        %{"data" => %{"name" => interaction_name, "type" => interaction_type}} = interaction,
        plugin_module
      )
      when is_binary(interaction_name) and is_integer(interaction_type) and is_atom(plugin_module) do
    middleware_list =
      plugin_module
      |> Plugin.get_definition_by_key(interaction_name, interaction_type)
      |> Map.get(:middleware, [])
      |> Enum.concat(@default_metadata)
      |> Enum.uniq()

    MiddlewareHandler.handle_middleware(middleware_list, interaction)
  end

  def process_interaction(
        interaction,
        parsed_application_command_name_list,
        interaction_type,
        parsed_options,
        processed_middleware_data,
        plugin_module
      ) do
    plugin_module.handle_interaction(
      parsed_application_command_name_list,
      interaction_type,
      parsed_options,
      interaction,
      processed_middleware_data
    )
  end

  defp build_application_command_metadata(
         %{name: name, children: children} = parent_meatadata_tree_node,
         [interaction_name_head | interaction_name_rest],
         current_metadata
       )
       when is_binary(name) and is_list(children) and is_binary(interaction_name_head) and is_list(interaction_name_rest) and
              is_map(current_metadata) do
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
      %{}
    end
  end

  defp build_application_command_metadata(%{}, _interaction_name_list, current_metadata) when is_map(current_metadata),
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

  defp parse_interaction_data(%{"name" => application_command_name_part, "options" => options}, resolved_data)
       when is_binary(application_command_name_part) and is_list(options) do
    Enum.reduce(options, {[application_command_name_part], %{}}, fn option,
                                                                    {parsed_application_command_name_list, parsed_options} ->
      {parsed_application_command_name_part, option_name, parsed_option_data} =
        parse_interaction_data(option, resolved_data)

      parsed_options =
        Map.put(parsed_options, option_name, parsed_option_data)

      parsed_application_command_name_list = [parsed_application_command_name_part | parsed_application_command_name_list]

      {parsed_application_command_name_list, parsed_options}
    end)
  end

  defp parse_interaction_data(%{"name" => option_name, "type" => option_type, "value" => option_value}, resolved_data)
       when is_binary(option_name) and is_integer(option_type) do
    resolved_option_value = get_resolved_option_value(option_type, option_value, resolved_data)
    {[], option_name, resolved_option_value}
  end

  defp parse_interaction_data(%{"name" => parsed_application_command_name_part}, _resolved_data)
       when is_binary(parsed_application_command_name_part) do
    {[parsed_application_command_name_part], %{}}
  end

  defp get_resolved_option_value(type, value, resolved_interaction_data)
       when is_integer(type) and type in [6, 7, 8, 11] and is_integer(value) do
    get_resolved_data_for_type(type, value, resolved_interaction_data)
  end

  defp get_resolved_option_value(type, value, resolved_interaction_data)
       when is_integer(type) and type == 9 and is_integer(value) do
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
       when is_integer(option_type) and option_type == 6 and is_integer(option_value) do
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
       when is_integer(option_type) and option_type in [7, 8, 11] and is_integer(option_value) do
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
