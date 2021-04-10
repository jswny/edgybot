defmodule Edgybot.Bot.Command.Resolver do
  @moduledoc false

  def resolve_command(parsed_command, _command_definitions)
      when is_list(parsed_command) and length(parsed_command) < 1,
      do: {:error, "no command provided"}

  def resolve_command(parsed_command, command_definitions) when is_list(parsed_command) do
    resolve_results =
      command_definitions
      |> Map.keys()
      |> Enum.map(&resolve_single_command(parsed_command, &1, command_definitions))

    resolve_result = Enum.find(resolve_results, &match?({:ok, _}, &1))

    if resolve_result do
      {:ok, resolved_command} = resolve_result
      [{:string, resolved_command_name} | resolved_command_args] = resolved_command

      {:ok, resolved_command_name, resolved_command_args}
    else
      {:error, "no matching command"}
    end
  end

  defp resolve_single_command(
         parsed_command,
         command_name_to_resolve_against,
         command_definitions
       )
       when is_list(parsed_command) and is_binary(command_name_to_resolve_against) do
    command_definition = command_definitions[command_name_to_resolve_against]
    command_definition = [{:static_string, command_name_to_resolve_against} | command_definition]

    resolve_command_against_definition(parsed_command, command_definition, [])
  end

  defp resolve_command_against_definition([], [], resolved_command)
       when is_list(resolved_command) do
    reversed_resolved_command = Enum.reverse(resolved_command)
    {:ok, reversed_resolved_command}
  end

  defp resolve_command_against_definition([], command_definition, resolved_command)
       when is_list(command_definition) and is_list(resolved_command) do
    {:error, "unused command parameters", command_definition}
  end

  defp resolve_command_against_definition(parsed_command, [], resolved_command)
       when is_list(parsed_command) and is_list(resolved_command) do
    {:error, "extraneous command aruments", parsed_command}
  end

  defp resolve_command_against_definition(
         [current_parsed_command_elem | parsed_command_rest] = parsed_command,
         [current_command_definition_elem | command_definition_rest] = command_definition,
         resolved_command
       )
       when is_list(parsed_command_rest) and is_list(command_definition_rest) and
              is_list(resolved_command) do
    elems_match? =
      resolve_command_elem_against_definition_elem(
        current_parsed_command_elem,
        current_command_definition_elem
      )

    if elems_match? do
      resolve_command_against_definition_matched_elems(
        parsed_command,
        command_definition,
        resolved_command
      )
    else
      {:error, "unsatisfied command definition element", current_parsed_command_elem,
       current_command_definition_elem}
    end
  end

  defp resolve_command_against_definition_matched_elems(
         [{:string, _} | _] = parsed_command,
         [:string | command_definition_rest],
         resolved_command
       )
       when is_list(parsed_command) and is_list(command_definition_rest) and
              is_list(resolved_command) do
    parsed_command_joined =
      parsed_command
      |> Enum.map(fn {:string, value} -> value end)
      |> Enum.join(" ")

    new_resolved_command = [
      {:string, parsed_command_joined}
      | resolved_command
    ]

    resolve_command_against_definition(
      [],
      [],
      new_resolved_command
    )
  end

  defp resolve_command_against_definition_matched_elems(
         [current_parsed_command_elem | parsed_command_rest],
         [_current_command_definition_elem | command_definition_rest],
         resolved_command
       )
       when is_list(parsed_command_rest) and is_list(command_definition_rest) and
              is_list(resolved_command) do
    new_resolved_command = [
      current_parsed_command_elem | resolved_command
    ]

    resolve_command_against_definition(
      parsed_command_rest,
      command_definition_rest,
      new_resolved_command
    )
  end

  defp resolve_command_elem_against_definition_elem(
         {:string, parsed_command_elem},
         {:static_string, definition_elem}
       )
       when is_binary(parsed_command_elem) and is_binary(definition_elem) do
    parsed_command_elem == definition_elem
  end

  defp resolve_command_elem_against_definition_elem(
         {:string, _parsed_command_elem},
         :string
       ) do
    true
  end

  defp resolve_command_elem_against_definition_elem(
         _parsed_command_elem,
         _command_definition_elem
       ),
       do: false
end
