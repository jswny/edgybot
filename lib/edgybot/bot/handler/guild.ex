defmodule Edgybot.Bot.Handler.Guild do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.Command.Registrar
  alias Nostrum.Api

  def handle_guild_available(guild) when is_map(guild) do
    guild_id = guild.id
    commands = Registrar.list_commands()

    register_guild_commands(guild_id, commands)
  end

  defp register_guild_commands(guild_id, commands)
       when is_integer(guild_id) and is_list(commands) do
    Logger.info("Registering commands for guild #{guild_id}...")

    commands
    |> Enum.map(fn command ->
      Task.async(fn ->
        command_name = command.name
        Logger.info("Registering command #{command_name} for guild #{guild_id}...")
        Api.create_guild_application_command(guild_id, command)
      end)
    end)
    |> Task.await_many()

    :noop
  end
end
