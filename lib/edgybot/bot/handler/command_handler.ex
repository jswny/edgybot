defmodule Edgybot.Bot.Handler.CommandHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.{Command, CommandRegistrar}
  alias Edgybot.Bot.Handler.MiddlewareHandler

  @default_metadata [:metadata]

  def handle_command(%{id: id, token: token, data: %{name: name, type: type}} = interaction)
      when is_integer(id) and is_binary(token) and is_binary(name) and is_integer(type) do
    Logger.debug("Handling command #{name} (type: #{type})...")

    matching_command_module = CommandRegistrar.get_module({name, type})

    case matching_command_module do
      nil ->
        :noop

      _ ->
        middleware_data =
          process_middleware_for_command(matching_command_module, type, interaction)

        Command.handle_interaction(matching_command_module, interaction, middleware_data)
    end
  end

  def process_middleware_for_command(command_module, command_type, interaction)
      when is_atom(command_module) and is_integer(command_type) and is_map(interaction) do
    middleware_list =
      command_module.get_command_definitions()
      |> Enum.find(nil, fn definition -> definition.type == command_type end)
      |> Map.get(:middleware, [])
      |> Enum.concat(@default_metadata)
      |> Enum.uniq()

    MiddlewareHandler.handle_middleware(middleware_list, interaction)
  end
end
