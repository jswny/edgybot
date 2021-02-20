defmodule Edgybot.Bot.Command.Matcher do
  def match_command(parsed_command, _command_definitions)
      when is_list(parsed_command) and length(parsed_command) < 1,
      do: {:error, "no command provided"}

  def match_command(parsed_command, command_definitions) when is_list(parsed_command) do
    command_list = Map.keys(command_definitions)

    command_name =
      Enum.find(command_list, &compare_command(parsed_command, &1, command_definitions))

    if command_name do
      {:ok, command_name}
    else
      {:error, "no matching command"}
    end
  end

  defp compare_command(parsed_command, command_name_to_match_against, command_definitions)
       when is_list(parsed_command) and is_binary(command_name_to_match_against) do
    command_definition = command_definitions[command_name_to_match_against]
    command_definition = [{:static_string, command_name_to_match_against} | command_definition]

    command_definition_count = Enum.count(command_definition)
    parsed_command_count = Enum.count(parsed_command)

    count_match = parsed_command_count == command_definition_count

    if count_match do
      compare_command_to_definition(parsed_command, command_definition)
    else
      false
    end
  end

  defp compare_command_to_definition(parsed_command, command_definition)
       when is_list(parsed_command) and is_list(command_definition) do
    parsed_command
    |> Enum.zip(command_definition)
    |> Enum.all?(fn {parsed_command_elem, command_definition_elem} ->
      compare_command_elem_to_definition_elem(parsed_command_elem, command_definition_elem)
    end)
  end

  defp compare_command_elem_to_definition_elem(
         {:string, parsed_elem_string},
         {:static_string, definition_elem_string}
       )
       when is_binary(parsed_elem_string) and is_binary(definition_elem_string) do
    parsed_elem_string == definition_elem_string
  end

  defp compare_command_elem_to_definition_elem(
         {:string, _parsed_elem_string},
         :string
       ) do
    true
  end

  defp compare_command_elem_to_definition_elem(_parsed_command_elem, _command_definition_elem),
    do: false
end
