defmodule Edgybot.Bot.Handler.InteractionHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.Handler.MiddlewareHandler
  alias Edgybot.Bot.Registrar.PluginRegistrar

  alias Nostrum.Struct.{
    ApplicationCommandInteractionData,
    ApplicationCommandInteractionDataOption,
    ApplicationCommandInteractionDataResolved,
    Interaction
  }

  @default_metadata [:metadata]

  defguardp valid_resolved_data(resolved_data)
            when is_struct(resolved_data, ApplicationCommandInteractionDataResolved) or
                   is_nil(resolved_data)

  def handle_interaction(%Interaction{data: %{name: name, type: type}} = interaction)
      when is_binary(name) and is_integer(type) do
    Logger.debug("Handling interaction #{name} (type: #{type})...")

    matching_plugin_module = PluginRegistrar.get_module({name, type})

    case matching_plugin_module do
      nil ->
        :noop

      _ ->
        middleware_data =
          process_middleware_for_interaction(matching_plugin_module, type, interaction)

        {application_command_name_list, application_command_type, options} =
          parse_interaction(interaction)

        matching_plugin_module.handle_interaction(
          application_command_name_list,
          application_command_type,
          options,
          interaction,
          middleware_data
        )
    end
  end

  defp process_middleware_for_interaction(
         plugin_module,
         interaction_type,
         %Interaction{} = interaction
       )
       when is_atom(plugin_module) and is_integer(interaction_type) do
    middleware_list =
      plugin_module.get_plugin_definitions()
      |> Enum.find(nil, fn definition ->
        definition.application_command.type == interaction_type
      end)
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
       when is_integer(type) and type in [6, 7, 8] and is_integer(value) and
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
       when is_integer(option_type) and option_type in [7, 8] and is_integer(option_value) and
              valid_resolved_data(resolved_interaction_data) do
    resolved_interaction_data_field =
      case option_type do
        7 -> :channels
        8 -> :roles
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
