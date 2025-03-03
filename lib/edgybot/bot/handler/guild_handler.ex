defmodule Edgybot.Bot.Handler.GuildHandler do
  @moduledoc false

  alias Edgybot.Bot.Registrar.PluginRegistrar
  alias Nostrum.Api
  alias Nostrum.Constants.ApplicationCommandOptionType
  alias Nostrum.Struct.Guild

  require Logger

  def handle_guild_available(%Guild{} = guild) do
    guild_id = guild.id
    guild_name = get_guild_name(guild_id)

    application_command_prefix = Application.get_env(:edgybot, :application_command_prefix)

    prefix_msg = if application_command_prefix, do: "with prefix #{application_command_prefix} ", else: ""
    Logger.debug(
      "Registering application commands #{prefix_msg}for guild #{guild_name}..."
    )

    PluginRegistrar.list_definitions()
    |> Enum.map(&Map.fetch!(&1, :application_command))
    |> apply_default_deny_permission()
    |> apply_global_options()
    |> apply_application_command_prefix(application_command_prefix)
    |> bulk_overwrite_guild_application_commands(guild_id)

    :noop
  end

  defp apply_global_options(application_command_definitions) when is_list(application_command_definitions) do
    Enum.map(application_command_definitions, fn application_command_definition ->
      hide_option = %{
        name: "hide",
        description: "Hides the response so only you can see it",
        type: 5,
        required: false
      }

      add_options(application_command_definition, [hide_option])
    end)
  end

  defp add_options(%{options: options} = node, new_options) when is_list(options) and is_list(new_options) do
    if Enum.any?(options, fn %{type: type} ->
         type in [
           ApplicationCommandOptionType.sub_command(),
           ApplicationCommandOptionType.sub_command_group()
         ]
       end) do
      %{node | options: Enum.map(options, &add_options(&1, new_options))}
    else
      %{node | options: options ++ new_options}
    end
  end

  defp add_options(%{type: 1} = node, new_options) when is_list(new_options) do
    Map.put(node, :options, new_options)
  end

  defp apply_application_command_prefix(application_command_definitions, nil)
       when is_list(application_command_definitions),
       do: application_command_definitions

  defp apply_application_command_prefix(application_command_definitions, application_command_prefix)
       when is_list(application_command_definitions) and is_binary(application_command_prefix) do
    Enum.map(application_command_definitions, fn application_command_definition ->
      name = application_command_definition.name
      Map.put(application_command_definition, :name, "#{application_command_prefix}#{name}")
    end)
  end

  defp apply_default_deny_permission(application_command_definitions) when is_list(application_command_definitions) do
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
