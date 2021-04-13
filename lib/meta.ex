defmodule Edgybot.Meta do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Edgybot.Meta.{Guild, Message, User}
  alias Edgybot.Repo

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def create_guild(attrs \\ %{}) do
    %Guild{}
    |> Guild.changeset(attrs)
    |> Repo.insert()
  end
end
