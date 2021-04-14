defmodule Edgybot.Meta.Member do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Edgybot.Meta.{Guild, User}

  @primary_key false
  schema "members" do
    belongs_to(:guild, Guild)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(member, params \\ %{}) do
    member
    |> cast(params, [:guild_id, :user_id])
    |> validate_required([:guild_id, :user_id])
    |> assoc_constraint(:guild)
    |> assoc_constraint(:user)
    |> unique_constraint([:guild_id, :user_id], name: :members_pkey)
  end
end
