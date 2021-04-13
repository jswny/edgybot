defmodule Edgybot.Meta.Message do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake
  alias Edgybot.Meta.User

  @primary_key {:id, :id, autogenerate: false}
  schema "messages" do
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(message, params \\ %{}) do
    message
    |> cast(params, [:id, :user_id])
    |> validate_required([:id, :user_id])
    |> validate_snowflake(:id)
    |> assoc_constraint(:user)
    |> unique_constraint(:id, name: :messages_pkey)
  end
end
