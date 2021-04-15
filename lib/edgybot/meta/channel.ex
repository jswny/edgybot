defmodule Edgybot.Meta.Channel do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake
  alias Edgybot.Meta.Guild

  @primary_key {:id, :id, autogenerate: false}
  schema "channels" do
    belongs_to(:guild, Guild)

    timestamps()
  end

  def changeset(channel, params \\ %{}) do
    channel
    |> cast(params, [:id, :guild_id])
    |> validate_required([:id, :guild_id])
    |> validate_snowflake(:id)
    |> assoc_constraint(:guild)
    |> unique_constraint(:id, name: :channels_pkey)
  end
end
