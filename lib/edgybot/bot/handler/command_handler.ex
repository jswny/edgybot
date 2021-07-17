defmodule Edgybot.Bot.Handler.CommandHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.CommandRegistrar

  def handle_command(%{id: id, token: token} = interaction)
      when is_integer(id) and is_binary(token) do
    command_name = interaction.data.name

    Logger.debug("Received command #{command_name}")

    matching_command = CommandRegistrar.get_command_module(command_name)

    case matching_command do
      nil -> :noop
      _ -> matching_command.handle_interaction(interaction)
    end
  end
end
