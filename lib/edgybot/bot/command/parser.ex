defmodule Edgybot.Bot.Command.Parser do
  @moduledoc false

  def parse_command(""), do: {:ok, []}

  def parse_command(command) when is_binary(command) do
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
end
