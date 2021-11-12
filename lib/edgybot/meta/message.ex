defmodule Edgybot.Meta.Message do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake
  alias Edgybot.Meta.{Channel, Member, Reaction}

  @primary_key {:id, :id, autogenerate: false}
  schema "messages" do
    belongs_to(:member, Member)
    belongs_to(:channel, Channel)

    has_many(:reactions, Reaction)

    timestamps()
  end

  def changeset(message, params \\ %{}) do
    message
    |> cast(params, [:id, :member_id, :channel_id])
    |> validate_required([:id, :member_id, :channel_id])
    |> validate_snowflake(:id)
    |> assoc_constraint(:member)
    |> assoc_constraint(:channel)
    |> unique_constraint(:id, name: :messages_pkey)
  end
end
