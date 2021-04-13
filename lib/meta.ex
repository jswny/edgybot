defmodule Edgybot.Meta do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Edgybot.Repo
  alias Edgybot.Meta.{User}

  def list_users() do
    Repo.all(User)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
