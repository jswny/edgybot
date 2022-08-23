defmodule Edgybot.Bot.Handler.GuildHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.Registrar.PluginRegistrar
  alias Nostrum.Api
  alias Nostrum.Struct.Guild

  def handle_guild_available(%Guild{} = guild) do
    guild_id = guild.id
    guild_name = get_guild_name(guild_id)

    Logger.debug("Registering application commands for guild #{guild_name}...")

    PluginRegistrar.list_definitions()
    |> Enum.map(&Map.fetch!(&1, :application_command))
    |> apply_default_deny_permission()
    |> bulk_overwrite_guild_application_commands(guild_id)

    :noop
  end

  defp apply_default_deny_permission(application_command_definitions)
       when is_list(application_command_definitions) do
    Enum.map(application_command_definitions, fn application_command_definition ->
      if Map.get(application_command_definition, :default_permission) == nil do
        Map.put(application_command_definition, :default_permission, false)
      else
        application_command_definition
      end
    end)
  end

  defp get_guild_name(guild_id) when is_integer(guild_id) do
    {:ok, guild} = Api.get_guild(guild_id)
    Map.get(guild, :name)
  end

  defp bulk_overwrite_guild_application_commands(application_command_definitions, guild_id)
       when is_list(application_command_definitions) and is_integer(guild_id) do
    {:ok, _application_commands} =
      Api.bulk_overwrite_guild_application_commands(guild_id, application_command_definitions)
  end
end
