defmodule Edgybot.Bot.Plugin do
  @moduledoc false

  alias Edgybot.Bot.Designer

  @type application_command_option_name :: binary()

  @type application_command_option_type_value :: 3..10

  @type application_command_option_description :: binary()

  @typep application_command_option_parameter :: %{
           optional(:required) => boolean(),
           name: application_command_option_name(),
           description: application_command_option_description(),
           type: application_command_option_type_value()
         }

  @type application_command_option_type_subcommand :: 1

  @type application_command_option_type_subcommand_group :: 2

  @typep application_command_definition_option ::
           %{
             name: application_command_option_name,
             description: binary(),
             type: application_command_option_type_subcommand_group(),
             options: [
               %{
                 name: binary(),
                 description: application_command_option_description(),
                 type: application_command_option_type_subcommand(),
                 options: [application_command_option_parameter()]
               }
             ]
           }
           | %{
               name: application_command_option_name(),
               description: application_command_option_description(),
               type: application_command_option_type_subcommand(),
               options: [application_command_option_parameter()]
             }
           | application_command_option_parameter()

  @type interaction_option_value :: binary()

  @type interaction_option ::
          {application_command_option_name(), application_command_option_type_value(),
           interaction_option_value()}

  @type application_command_type :: 1..3

  @type plugin_definition :: %{
          optional(:options) => [application_command_definition_option()],
          optional(:default_permission) => boolean(),
          optional(:middleware) => [atom()],
          name: binary(),
          description: binary(),
          type: application_command_type()
        }

  @type application_command_name_list :: nonempty_list(binary())

  @type interaction_response ::
          {:success, binary()}
          | {:warning, binary()}
          | {:error, binary()}
          | {:success, Designer.options()}
          | {:warning, Designer.options()}
          | {:error, Designer.options()}

  @callback get_plugin_definitions() :: [plugin_definition()]

  @callback handle_interaction(
              application_command_name_list(),
              application_command_type,
              [interaction_option],
              Nostrum.Struct.Interaction.t(),
              map()
            ) :: interaction_response()

  def handle_interaction(plugin_module, interaction, middleware_data)
      when is_atom(plugin_module) and is_map(interaction) and is_map(middleware_data) do
    {application_command_name_list, application_command_type, options} =
      parse_interaction(interaction)

    plugin_module.handle_interaction(
      application_command_name_list,
      application_command_type,
      options,
      interaction,
      middleware_data
    )
  end

  defp parse_interaction(%{data: %{type: application_command_type} = data})
       when is_integer(application_command_type) and is_map(data) do
    resolved_data = Map.get(data, :resolved)

    {parsed_application_command_name_list, parsed_options} =
      parse_interaction(data, resolved_data)

    {flatten_reverse(parsed_application_command_name_list), application_command_type,
     flatten_reverse(parsed_options)}
  end

  defp parse_interaction(
         %{name: application_command_name_part, options: options},
         resolved_data
       )
       when is_binary(application_command_name_part) and is_list(options) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    Enum.reduce(options, {[application_command_name_part], []}, fn option,
                                                                   {parsed_application_command_name_list,
                                                                    parsed_options} ->
      {parsed_application_command_name_part, parsed_option} =
        parse_interaction(option, resolved_data)

      {[parsed_application_command_name_part | parsed_application_command_name_list],
       [parsed_option | parsed_options]}
    end)
  end

  defp parse_interaction(
         %{name: option_name, type: option_type, value: option_value},
         resolved_data
       )
       when is_binary(option_name) and is_integer(option_type) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    resolved_option_value = get_resolved_option_value(option_type, option_value, resolved_data)
    parsed_option = {option_name, option_type, resolved_option_value}
    {[], [parsed_option]}
  end

  defp parse_interaction(%{name: parsed_application_command_name_part}, _resolved_data)
       when is_binary(parsed_application_command_name_part) do
    {[parsed_application_command_name_part], []}
  end

  defp get_resolved_option_value(type, value, resolved_data)
       when is_integer(type) and type in [6, 7, 8] and is_integer(value) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    get_resolved_data_for_type(type, value, resolved_data)
  end

  defp get_resolved_option_value(type, value, resolved_data)
       when is_integer(type) and type == 9 and is_integer(value) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    [6, 8]
    |> Enum.map(fn t ->
      try do
        get_resolved_data_for_type(t, value, resolved_data)
      rescue
        KeyError -> nil
      end
    end)
    |> Enum.find(&(&1 != nil))
  end

  defp get_resolved_option_value(_type, value, _resolved_data), do: value

  defp get_resolved_data_for_type(option_type, option_value, resolved_interaction_data)
       when is_integer(option_type) and option_type == 6 and is_integer(option_value) and
              (is_map(resolved_interaction_data) or is_nil(resolved_interaction_data)) do
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
              (is_map(resolved_interaction_data) or is_nil(resolved_interaction_data)) do
    resolved_data_field =
      case option_type do
        7 -> :channels
        8 -> :roles
      end

    resolved_interaction_data
    |> Map.fetch!(resolved_data_field)
    |> Map.fetch!(option_value)
  end

  defp flatten_reverse(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.reverse()
  end
end
