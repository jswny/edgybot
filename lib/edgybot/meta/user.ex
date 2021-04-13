defmodule Edgybot.Meta.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake

  @primary_key {:id, :id, autogenerate: false}
  schema "users" do
    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:id])
    |> validate_required([:id])
    |> validate_snowflake(:id)
    |> unique_constraint(:id, name: :users_pkey)
  end
end
