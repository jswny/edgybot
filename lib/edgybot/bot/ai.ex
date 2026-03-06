defmodule Edgybot.Bot.AI do
  @moduledoc false

  alias Edgybot.Bot.AI.AIChannel
  alias Edgybot.External.Discord
  alias Edgybot.Repo

  require Ecto.Query

  def set_channel_settings(attrs) do
    changeset = AIChannel.changeset(%AIChannel{}, attrs)
    update_fields = Map.keys(changeset.changes)

    Repo.insert(
      changeset,
      on_conflict: {:replace, update_fields},
      conflict_target: [:channel_id]
    )
  end

  def get_channel_settings(channel_id) do
    AIChannel
    |> Ecto.Query.where(channel_id: ^channel_id)
    |> Repo.one()
  end

  def generate_chat_messages_with_roles(channel_messages, guild_id, assistant_user_id) do
    Enum.map(channel_messages, fn message ->
      author_id = message.author.id

      if author_id == assistant_user_id do
        %{role: "assistant", content: message.content}
      else
        generate_user_message(guild_id, author_id, message.content)
      end
    end)
  end

  def generate_user_message(guild_id, user_id, content) do
    %{
      role: "user",
      name: Discord.get_user_sanitized_chat_message_name(guild_id, user_id),
      content: content
    }
  end
end
