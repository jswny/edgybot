defmodule Edgybot.Bot.Command.Command do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Nostrum.Api
  alias Nostrum.Cache.Me

  @behaviour Edgybot.Bot.Command
  @api_error_no_permissions {:error, %{response: %{code: 10_066}, status_code: 404}}

  @impl true
  def get_command do
    %{
      name: "command",
      description: "Command management",
      default_permission: true,
      options: [
        %{
          name: "permissions",
          description: "Command permissions management",
          type: 2,
          options: [
            %{
              name: "list",
              description: "List the permissions for a command",
              type: 1,
              options: [
                %{
                  name: "command",
                  description: "The command for which the permissions should be returned",
                  type: 3,
                  required: true
                }
              ]
            },
            %{
              name: "add-role",
              description: "Allow or deny access to a command for a specific role",
              type: 1,
              options: [
                %{
                  name: "command",
                  description: "The command for which the permissions should be adjusted",
                  type: 3,
                  required: true
                },
                %{
                  name: "role",
                  description: "The role to allow or deny access to the command",
                  type: 8,
                  required: true
                },
                %{
                  name: "allow",
                  description: "Whether to allow or deny permission",
                  type: 5,
                  required: true
                }
              ]
            },
            %{
              name: "remove-role",
              description: "Remove a role permission for a command",
              type: 1,
              options: [
                %{
                  name: "command",
                  description: "The command for which the permissions should be adjusted",
                  type: 3,
                  required: true
                },
                %{
                  name: "role",
                  description: "The role to remove from the permissions",
                  type: 8,
                  required: true
                }
              ]
            }
          ]
        }
      ]
    }
  end

  @impl true
  def handle_interaction(interaction) when is_map(interaction) do
    subcommand_group_option = get_subcommand_group_option(interaction)
    guild_id = Map.get(interaction, :guild_id)
    subcommand_group_name = Map.get(subcommand_group_option, :name)

    case subcommand_group_name do
      "permissions" ->
        handle_subcommand_group_permissions(subcommand_group_option, guild_id)

      _ ->
        {:error, "Unhandled subcommand group"}
    end
  end

  defp handle_subcommand_group_permissions(subcommand_group_option, guild_id)
       when is_map(subcommand_group_option) and is_integer(guild_id) do
    subcommand_option = get_subcommand_option(subcommand_group_option)
    subcommand_name = Map.get(subcommand_option, :name)

    case subcommand_name do
      "list" ->
        handle_subcommand_permissions_list(subcommand_option, guild_id)

      "add-role" ->
        handle_subcommand_permissions_add_role(subcommand_option, guild_id)

      "remove-role" ->
        handle_subcommand_permissions_remove_role(subcommand_option, guild_id)

      _ ->
        {:error, "Unhandled subcommand"}
    end
  end

  defp handle_subcommand_permissions_list(subcommand_option, guild_id)
       when is_map(subcommand_option) and is_integer(guild_id) do
    options = Map.get(subcommand_option, :options)

    command_name = get_option_value(options, 0)

    command_id = get_guild_command_id(command_name, guild_id)

    if command_id == nil do
      command_does_not_exist_response(command_name)
    else
      permissions_list = get_command_permissions(command_id, guild_id)

      {:success, build_permissions_response_options(permissions_list, command_name, guild_id)}
    end
  end

  defp handle_subcommand_permissions_add_role(subcommand_option, guild_id)
       when is_map(subcommand_option) and is_integer(guild_id) do
    options = Map.get(subcommand_option, :options)

    command_name = get_option_value(options, 0)

    role_id =
      options
      |> get_option_value(1)
      |> String.to_integer()

    allow = get_option_value(options, 2)

    command_id = get_guild_command_id(command_name, guild_id)

    if command_id == nil do
      command_does_not_exist_response(command_name)
    else
      route =
        "/applications/#{get_application_id()}/guilds/#{guild_id}/commands/#{command_id}/permissions"

      new_permission = %{
        id: role_id,
        type: 1,
        permission: allow
      }

      current_permissions = get_command_permissions(command_id, guild_id)

      body = %{
        permissions: [new_permission | current_permissions]
      }

      {:ok, _permissions} = Api.request(:put, route, body)

      action_message =
        if allow do
          "#{Designer.emoji_yes()} allowed"
        else
          "#{Designer.emoji_no()} disallowed"
        end

      {:success,
       "Successfully #{action_message} #{Designer.role_mention(role_id)} use of command #{Designer.code_inline(command_name)}"}
    end
  end

  defp handle_subcommand_permissions_remove_role(subcommand_option, guild_id)
       when is_map(subcommand_option) and is_integer(guild_id) do
    options = Map.get(subcommand_option, :options)

    command_name = get_option_value(options, 0)

    role_id =
      options
      |> get_option_value(1)
      |> String.to_integer()

    command_id = get_guild_command_id(command_name, guild_id)

    if command_id == nil do
      command_does_not_exist_response(command_name)
    else
      current_permissions = get_command_permissions(command_id, guild_id)
      current_permissions_count = Enum.count(current_permissions)

      new_permissions =
        Enum.filter(current_permissions, fn permission ->
          permission_role_id =
            permission
            |> Map.get("id")
            |> String.to_integer()

          permission_role_id != role_id
        end)

      new_permissions_count = Enum.count(new_permissions)

      role_mention = Designer.role_mention(role_id)

      if current_permissions_count == new_permissions_count do
        {:warning,
         "#{role_mention} has no permissions for command #{Designer.code_inline(command_name)}!"}
      else
        body = %{
          permissions: new_permissions
        }

        route =
          "/applications/#{get_application_id()}/guilds/#{guild_id}/commands/#{command_id}/permissions"

        {:ok, _permissions} = Api.request(:put, route, body)

        {:success,
         "Removed permission for #{role_mention} for command #{Designer.code_inline(command_name)}"}
      end
    end
  end

  defp build_permissions_response_options(permissions, command_name, guild_id)
       when is_list(permissions) and is_binary(command_name) and is_integer(guild_id) do
    {allowed_role_ids, disallowed_role_ids} =
      Enum.reduce(
        permissions,
        {[], []},
        fn permission, {allowed_list, disallowed_list} ->
          role_id =
            permission
            |> Map.get("id")
            |> String.to_integer()

          allow? = Map.get(permission, "permission")

          if allow? do
            {[role_id | allowed_list], disallowed_list}
          else
            {allowed_list, [role_id | disallowed_list]}
          end
        end
      )

    allowed_role_mentions = build_role_mentions_field_content(allowed_role_ids)
    disallowed_role_mentions = build_role_mentions_field_content(disallowed_role_ids)

    allowed_field = %{
      name: "#{Designer.emoji_yes()} Allowed",
      value: if(allowed_role_mentions == "", do: "None!", else: allowed_role_mentions)
    }

    disallowed_field = %{
      name: "#{Designer.emoji_no()} Disallowed",
      value: if(disallowed_role_mentions == "", do: "None!", else: disallowed_role_mentions)
    }

    [
      title: "Permissions for #{Designer.code_inline(command_name)}",
      fields: [allowed_field, disallowed_field]
    ]
  end

  defp build_role_mentions_field_content(role_ids) when is_list(role_ids) do
    role_ids
    |> Enum.map(fn role_id -> Designer.role_mention(role_id) end)
    |> Enum.join("\n")
  end

  defp get_command_permissions(command_id, guild_id)
       when is_integer(command_id) and is_integer(guild_id) do
    route =
      "/applications/#{get_application_id()}/guilds/#{guild_id}/commands/#{command_id}/permissions"

    response = Api.request(:get, route)

    case response do
      {:ok, permissions_json_string} ->
        permissions_json_string
        |> Jason.decode!()
        |> Map.get("permissions")

      @api_error_no_permissions ->
        []

      _ ->
        {:ok, _} = response
    end
  end

  defp get_guild_command_id(command_name, guild_id)
       when is_binary(command_name) and is_integer(guild_id) do
    {:ok, commands} = Api.get_guild_application_commands(guild_id)

    command_name = Enum.find(commands, fn command -> Map.get(command, :name) == command_name end)

    if command_name == nil do
      nil
    else
      command_name
      |> Map.get(:id)
      |> String.to_integer()
    end
  end

  defp get_subcommand_group_option(interaction) when is_map(interaction) do
    interaction
    |> Map.get(:data)
    |> Map.get(:options)
    |> Enum.at(0)
  end

  defp get_subcommand_option(subcommand_group_option) when is_map(subcommand_group_option) do
    subcommand_group_option
    |> Map.get(:options)
    |> Enum.at(0)
  end

  defp get_option_value(options, index) when is_list(options) and is_integer(index) do
    options
    |> Enum.at(index)
    |> Map.get(:value)
  end

  defp get_application_id, do: Me.get().id

  defp command_does_not_exist_response(command_name) when is_binary(command_name) do
    {:warning, "Command #{Designer.code_inline(command_name)} does not exist!"}
  end
end
