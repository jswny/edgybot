defmodule Edgybot.Bot.Handler.Guild do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.Command.Registrar
  alias Nostrum.Api

  def handle_guild_available(guild) when is_map(guild) do
    application_id = get_discord_application_id()
    guild_id = guild.id
    commands = Registrar.list_commands()

    register_guild_commands(application_id, guild_id, commands)
  end

  defp register_guild_commands(application_id, guild_id, commands)
       when is_integer(application_id) and is_integer(guild_id) and is_list(commands) do
    Logger.info("Registering commands for guild #{guild_id}...")

    commands
    |> Enum.map(fn command ->
      Task.async(fn ->
        command_name = command.name
        Logger.info("Registering command #{command_name} for guild #{guild_id}...")
        Api.create_guild_application_command(application_id, guild_id, command)
      end)
    end)
    |> Task.await_many()

    :noop
  end

  defp get_discord_application_id() do
    Nostrum.Cache.Me.get().id
  end
end
