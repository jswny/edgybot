defmodule Edgybot.Meta.Guild do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake
  alias Edgybot.Meta.{Channel, Member, Role}

  @primary_key {:id, :id, autogenerate: false}
  schema "guilds" do
    has_many(:members, Member)
    has_many(:roles, Role)
    has_many(:channels, Channel)

    timestamps()
  end

  def changeset(guild, params \\ %{}) do
    guild
    |> cast(params, [:id])
    |> validate_required([:id])
    |> validate_snowflake(:id)
    |> unique_constraint(:id, name: :guilds_pkey)
  end
end
