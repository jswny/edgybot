defmodule Edgybot.Bot.Handler.Command do
  @moduledoc false

  alias Edgybot.Bot

  @commands %{
    "ping" => []
  }

  def handle_command(message) do
    command = message.content

    with {:ok, cleaned_command} <- clean_command(command),
         {:ok, parsed_command} <- parse_command(cleaned_command),
         {:ok, matched_command_name} <- match_command(parsed_command),
         {:ok, response} <- handle_matched_command(parsed_command, matched_command_name) do
      response
    else
      err -> err
    end
  end

  def is_command?(message) do
    message.content
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

  defp match_command(parsed_command) when is_list(parsed_command) and length(parsed_command) < 1,
    do: {:error, "no command provided"}

  defp match_command(parsed_command) when is_list(parsed_command) do
    command_list = Map.keys(@commands)

    command_name = Enum.find(command_list, &compare_command(parsed_command, &1))

    if command_name do
      {:ok, command_name}
    else
      {:error, "no matching command"}
    end
  end

  defp compare_command(parsed_command, command_name_to_match_against)
       when is_list(parsed_command) and is_binary(command_name_to_match_against) do
    command_definition = @commands[command_name_to_match_against]
    command_definition = [{:string, command_name_to_match_against} | command_definition]

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

  defp compare_command_elem_to_definition_elem(parsed_command_elem, command_definition_elem) do
    parsed_command_elem_type = elem(parsed_command_elem, 0)
    command_definition_elem_type = elem(command_definition_elem, 0)
    parsed_command_elem_type == command_definition_elem_type
  end

  defp handle_matched_command(parsed_command, matched_command_name) do
    case matched_command_name do
      "ping" -> command_ping(parsed_command)
    end
  end

  defp command_ping(_parsed_command) do
    response = {:message, "Pong!"}
    {:ok, response}
  end
end
