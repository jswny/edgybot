defmodule Edgybot.Meta do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Edgybot.Meta.{Channel, Guild, Member, Message, Reaction, Role, User}
  alias Edgybot.Repo

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  def create_guild(attrs \\ %{}) do
    %Guild{}
    |> Guild.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  def create_reaction(attrs \\ %{}) do
    %Reaction{}
    |> Reaction.changeset(attrs)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:message_id, :member_id, :emote_id]
    )
  end

  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  def create_member(attrs \\ %{}) do
    %Member{}
    |> Member.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:guild_id, :user_id])
  end
end
