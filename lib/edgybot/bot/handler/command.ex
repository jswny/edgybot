defmodule Edgybot.Bot.Handler.Command do
  @moduledoc false

  alias Edgybot.Bot
  alias Edgybot.Bot.Command.{Parser, Resolver}

  @command_definitions %{
    "ping" => []
  }

  def handle_command(command, context)
      when is_binary(command) and is_map(context) do
    command_definitions = @command_definitions

    with {:ok, cleaned_command} <- clean_command(command),
         {:ok, parsed_command} <- Parser.parse_command(cleaned_command),
         {:ok, resolved_command_name, _resolved_command_args} <-
           Resolver.resolve_command(parsed_command, command_definitions),
         {:ok, response} <-
           handle_resolved_command(parsed_command, resolved_command_name, context) do
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

  defp handle_resolved_command(parsed_command, resolved_command_name, context)
       when is_list(parsed_command) and is_binary(resolved_command_name) do
    case resolved_command_name do
      "ping" ->
        command_ping(parsed_command, context)
    end
  end

  defp command_ping(_parsed_command, _context) do
    response = {:message, "Pong!"}
    {:ok, response}
  end
end
