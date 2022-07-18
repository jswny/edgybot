defmodule Edgybot.Bot.Command do
  @moduledoc false

  alias Edgybot.Bot.Designer

  @type application_command_type :: 1..3

  @typep application_command_definition_parameter_option :: %{
           optional(:required) => boolean,
           name: binary(),
           description: binary(),
           type: 3..10
         }

  @typep application_command_definition_option ::
           %{
             name: binary(),
             description: binary(),
             type: 2,
             options: [
               %{
                 name: binary(),
                 description: binary(),
                 type: 1,
                 options: [application_command_definition_parameter_option()]
               }
             ]
           }
           | %{
               name: binary(),
               description: binary(),
               type: 1,
               options: [application_command_definition_parameter_option()]
             }
           | application_command_definition_parameter_option()

  @type command_option_name :: binary()

  @type command_option_type :: 3..10

  @type command_option_value :: binary()

  @type command_option :: {command_option_name(), command_option_type(), command_option_value()}

  @callback get_command_definitions() :: [
              %{
                optional(:options) => [application_command_definition_option()],
                optional(:default_permission) => boolean(),
                optional(:middleware) => [atom()],
                name: binary(),
                description: binary(),
                type: application_command_type()
              }
            ]

  @callback handle_command(
              nonempty_list(binary()),
              application_command_type,
              [command_option],
              Nostrum.Struct.Interaction.t(),
              map()
            ) ::
              {:success, binary()}
              | {:warning, binary()}
              | {:error, binary()}
              | {:success, Designer.options()}
              | {:warning, Designer.options()}
              | {:error, Designer.options()}

  def handle_interaction(command_module, interaction, middleware_data)
      when is_atom(command_module) and is_map(interaction) and is_map(middleware_data) do
    {command, application_command_type, options} = parse_interaction(interaction)

    command_module.handle_command(
      command,
      application_command_type,
      options,
      interaction,
      middleware_data
    )
  end

  defp parse_interaction(%{data: %{type: application_command_type} = command_data})
       when is_integer(application_command_type) and is_map(command_data) do
    resolved_data = Map.get(command_data, :resolved)

    {parsed_command, parsed_options} = parse_interaction(command_data, resolved_data)
    {flatten_reverse(parsed_command), application_command_type, flatten_reverse(parsed_options)}
  end

  defp parse_interaction(%{name: name, options: options} = command_data, resolved_data)
       when is_binary(name) and is_list(options) and is_map(command_data) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    Enum.reduce(options, {[name], []}, fn option, {parsed_command, parsed_options} ->
      {parsed_command_part, parsed_option} = parse_interaction(option, resolved_data)
      {[parsed_command_part | parsed_command], [parsed_option | parsed_options]}
    end)
  end

  defp parse_interaction(%{name: name, type: type, value: value}, resolved_data)
       when is_binary(name) and is_integer(type) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    resolved_value = get_resolved_option_value(type, value, resolved_data)
    parsed_option = {name, type, resolved_value}
    {[], [parsed_option]}
  end

  defp parse_interaction(%{name: name}, _resolved_data) when is_binary(name) do
    parsed_command_part = name
    {[parsed_command_part], []}
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

  defp get_resolved_data_for_type(type, value, resolved_data)
       when is_integer(type) and type == 6 and is_integer(value) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    user_data =
      resolved_data
      |> Map.fetch!(:users)
      |> Map.fetch!(value)

    member_data =
      resolved_data
      |> Map.fetch!(:members)
      |> Map.fetch!(value)

    Map.merge(user_data, member_data)
  end

  defp get_resolved_data_for_type(type, value, resolved_data)
       when is_integer(type) and type in [7, 8] and is_integer(value) and
              (is_map(resolved_data) or is_nil(resolved_data)) do
    resolved_data_field =
      case type do
        7 -> :channels
        8 -> :roles
      end

    resolved_data
    |> Map.fetch!(resolved_data_field)
    |> Map.fetch!(value)
  end

  defp flatten_reverse(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.reverse()
  end
end
