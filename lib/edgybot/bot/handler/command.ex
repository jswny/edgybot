defmodule Edgybot.Bot.Handler.Command do
  @moduledoc false

  alias Edgybot.Bot
  alias Edgybot.Bot.Command.{Matcher, Parser}

  @command_definitions %{
    "ping" => []
  }

  def handle_command(command)
      when is_binary(command) do
    command_definitions = @command_definitions

    with {:ok, cleaned_command} <- clean_command(command),
         {:ok, parsed_command} <- Parser.parse_command(cleaned_command),
         {:ok, matched_command_name} <-
           Matcher.match_command(parsed_command, command_definitions),
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

  defp handle_matched_command(parsed_command, matched_command_name)
       when is_list(parsed_command) and is_binary(matched_command_name) do
    case matched_command_name do
      "ping" ->
        command_ping(parsed_command)
    end
  end

  defp command_ping(_parsed_command) do
    response = {:message, "Pong!"}
    {:ok, response}
  end
end
