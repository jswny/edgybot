defmodule Edgybot.Bot.Handler.Command do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.Command.Registrar

  def handle_command(interaction) when is_map(interaction) do
    command_name = interaction.data.name

    Logger.debug("Received command #{command_name}")

    matching_command = Registrar.get_command_module(command_name)
    matching_command.handle_interaction(interaction)
  end
end
