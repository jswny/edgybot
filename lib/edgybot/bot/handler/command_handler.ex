defmodule Edgybot.Bot.Handler.CommandHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.{Command, CommandRegistrar}

  def handle_command(%{id: id, token: token} = interaction)
      when is_integer(id) and is_binary(token) do
    command_name = interaction.data.name
    command_type = interaction.data.type

    Logger.debug("Handling command #{command_name} (type: #{command_type})...")

    matching_command_module = CommandRegistrar.get_command_module(command_name, command_type)

    case matching_command_module do
      nil -> :noop
      _ -> Command.handle_interaction(matching_command_module, interaction)
    end
  end
end
