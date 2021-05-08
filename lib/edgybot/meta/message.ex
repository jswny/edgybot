defmodule Edgybot.Meta.Message do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake
  alias Edgybot.Meta.{Channel, User}

  @primary_key {:id, :id, autogenerate: false}
  schema "messages" do
    belongs_to(:user, User)
    belongs_to(:channel, Channel)

    timestamps()
  end

  def changeset(message, params \\ %{}) do
    message
    |> cast(params, [:id, :user_id, :channel_id])
    |> validate_required([:id, :user_id, :channel_id])
    |> validate_snowflake(:id)
    |> assoc_constraint(:user)
    |> assoc_constraint(:channel)
    |> unique_constraint(:id, name: :messages_pkey)
  end
end
