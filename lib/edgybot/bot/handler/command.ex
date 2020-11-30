defmodule Edgybot.Bot.Handler.Command do
  @moduledoc false

  alias Edgybot.Bot

  @command_definitions %{
    "ping" => []
  }

  def handle_command(command, command_definitions)
      when is_binary(command) and is_map(command_definitions),
      do: handle_command_with_definitions(command, command_definitions)

  def handle_command(command)
      when is_binary(command),
      do: handle_command_with_definitions(command, @command_definitions)

  defp handle_command_with_definitions(command, command_definitions)
       when is_binary(command) and is_map(command_definitions) do
    with {:ok, cleaned_command} <- clean_command(command),
         {:ok, parsed_command} <- parse_command(cleaned_command),
         {:ok, matched_command_name} <- match_command(parsed_command, command_definitions),
         {:ok, response} <- handle_matched_command(parsed_command, matched_command_name) do
      response
    else
      err -> err
    end
  end

  def is_command?(content) when is_binary(content) do
    content
    |> String.trim()
    |> String.starts_with?(Bot.prefix())
  end

  defp clean_command(command) when is_binary(command) do
    cleaned =
      command
      |> String.replace(Bot.prefix(), "")
      |> String.trim()

    {:ok, cleaned}
  end

  defp parse_command(command) when is_binary(command) do
    parsed =
      command
      |> String.split(" ")
      |> Enum.reduce([], fn elem, acc ->
        parsed_part = parse_command_part(elem)
        [parsed_part | acc]
      end)
      |> Enum.reverse()

    {:ok, parsed}
  end

  defp parse_command_part(part) when is_binary(part) do
    cond do
      String.match?(part, ~r/<@!\d+>/) ->
        {:mention_user}

      String.match?(part, ~r/<@&\d+>/) ->
        {:mention_role}

      true ->
        {:string, part}
    end
  end

  defp match_command(parsed_command, _command_definitions)
       when is_list(parsed_command) and length(parsed_command) < 1,
       do: {:error, "no command provided"}

  defp match_command(parsed_command, command_definitions) when is_list(parsed_command) do
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

  defp handle_matched_command(parsed_command, matched_command_name)
       when is_list(parsed_command) and is_binary(matched_command_name) do
    case matched_command_name do
      "ping" -> command_ping(parsed_command)
    end
  end

  defp command_ping(_parsed_command) do
    response = {:message, "Pong!"}
    {:ok, response}
  end
end
