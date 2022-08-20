defmodule Edgybot.Bot.Handler.GuildHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.PluginRegistrar
  alias Nostrum.Api

  def handle_guild_available(guild) when is_map(guild) do
    guild_id = guild.id
    guild_name = get_guild_name(guild_id)

    Logger.debug("Registering commands for guild #{guild_name}...")

    PluginRegistrar.list_definitions()
    |> apply_default_deny_permission()
    |> bulk_overwrite_guild_application_commands(guild_id)

    :noop
  end

  defp apply_default_deny_permission(commands) when is_list(commands) do
    Enum.map(commands, fn command ->
      if Map.get(command, :default_permission) == nil do
        Map.put(command, :default_permission, false)
      else
        command
      end
    end)
  end

  defp get_guild_name(guild_id) when is_integer(guild_id) do
    {:ok, guild} = Api.get_guild(guild_id)
    Map.get(guild, :name)
  end

  defp bulk_overwrite_guild_application_commands(commands, guild_id)
       when is_list(commands) and is_integer(guild_id) do
    {:ok, _application_commands} =
      Api.bulk_overwrite_guild_application_commands(guild_id, commands)
  end
end
