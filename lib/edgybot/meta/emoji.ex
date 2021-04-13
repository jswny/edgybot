defmodule Edgybot.Meta.Emoji do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake

  @primary_key {:id, :id, autogenerate: false}
  schema "emoji" do
    timestamps()
  end

  def changeset(emoji, params \\ %{}) do
    emoji
    |> cast(params, [:id])
    |> validate_required([:id])
    |> validate_snowflake(:id)
    |> unique_constraint(:id, name: :emoji_pkey)
  end
end
