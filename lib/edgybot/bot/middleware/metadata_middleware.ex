defmodule Edgybot.Bot.Middleware.MetadataMiddleware do
  @moduledoc false

  alias Edgybot.Meta
  alias Nostrum.Struct.Interaction

  @behaviour Edgybot.Bot.Middleware

  @impl true
  def get_middleware_definition, do: %{name: :metadata, order: 1}

  @impl true
  def process_interaction(%Interaction{} = interaction) do
    {:ok, create_metadata(interaction)}
  end

  defp create_metadata(%Interaction{} = interaction) do
    with user_id <- interaction.member.user.id,
         guild_id <- interaction.guild_id,
         channel_id <- interaction.channel_id,
         {:ok, user} <- Meta.create_user(%{id: user_id}),
         {:ok, member} <- Meta.create_member(%{guild_id: guild_id, user_id: user_id}),
         roles <- create_roles(interaction, guild_id),
         {:ok, guild} <- Meta.create_guild(%{id: guild_id}),
         {:ok, channel} <- Meta.create_guild(%{id: channel_id, guild_id: guild_id}),
         messages <- create_messages(interaction, channel_id) do
      data = %{
        user: user,
        member: member,
        roles: roles,
        guild: guild,
        channel: channel,
        messages: messages
      }

      {:ok, data}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_roles(%Interaction{} = interaction, guild_id) when is_integer(guild_id) do
    interaction
    |> Map.fetch!(:member)
    |> Map.fetch!(:roles)
    |> Enum.reduce([], fn role_id, acc ->
      {:ok, role} = Meta.create_role(%{id: role_id, guild_id: guild_id})
      [role | acc]
    end)
  end

  defp create_messages(%Interaction{} = interaction, channel_id) when is_integer(channel_id) do
    interaction
    |> get_in([Access.key(:data), Access.key(:resolved), Access.key(:messages)])
    |> case do
      nil -> []
      messages -> messages
    end
    |> Enum.reduce([], fn {message_id, _message}, acc ->
      {:ok, message} = Meta.create_message(%{id: message_id, channel_id: channel_id})
      [message | acc]
    end)
  end
end
