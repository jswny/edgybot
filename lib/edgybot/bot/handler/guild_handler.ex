defmodule Edgybot.Bot.Handler.GuildHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.CommandRegistrar
  alias Nostrum.Api

  def handle_guild_available(guild) when is_map(guild) do
    guild_id = guild.id
    guild_name = get_guild_name(guild_id)

    commands =
      CommandRegistrar.list_commands()
      |> apply_default_deny_permission()

    remove_unused_guild_application_comands(guild_id, guild_name, commands)

    register_guild_commands(guild_id, guild_name, commands)
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

  defp remove_unused_guild_application_comands(guild_id, guild_name, commands)
       when is_integer(guild_id) and is_binary(guild_name) and is_list(commands) do
    {:ok, current_commands_response} = Api.get_guild_application_commands(guild_id)

    current_commands =
      current_commands_response
      |> Enum.map(fn command -> {command.name, command.id} end)
      |> Map.new()

    unused_command_names =
      get_unused_guild_application_comand_names(guild_id, current_commands, commands)

    unless Enum.empty?(unused_command_names) do
      Logger.info(
        "Removing unused commands for guild #{guild_name}: #{Enum.join(unused_command_names, ",")}"
      )

      Enum.each(unused_command_names, fn unused_command_name ->
        command_id = Map.fetch!(current_commands, unused_command_name)
        {:ok} = Api.delete_guild_application_command(guild_id, command_id)
      end)
    end
  end

  defp get_unused_guild_application_comand_names(guild_id, current_commands, commands)
       when is_integer(guild_id) and is_map(current_commands) and is_list(commands) do
    command_names_set =
      commands
      |> Enum.map(fn command -> command.name end)
      |> MapSet.new()

    current_commands
    |> Enum.map(fn {command_name, _} -> command_name end)
    |> MapSet.new()
    |> MapSet.difference(command_names_set)
  end

  defp get_guild_name(guild_id) when is_integer(guild_id) do
    {:ok, guild} = Api.get_guild(guild_id)
    guild.name
  end

  defp register_guild_commands(guild_id, guild_name, commands)
       when is_integer(guild_id) and is_binary(guild_name) and is_list(commands) do
    Logger.debug("Registering commands for guild #{guild_name}...")

    commands
    |> Enum.map(fn command ->
      Task.async(fn ->
        Api.create_guild_application_command(guild_id, command)
      end)
    end)
    |> Task.await_many()

    :noop
  end
end
