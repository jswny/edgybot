defmodule Edgybot.Meta.Reaction do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Edgybot.Meta.{Message, User}

  @primary_key {:id, :id, autogenerate: false}
  schema "reactions" do
    belongs_to(:message, Message)
    belongs_to(:user, User)
    field(:emoji, :string)

    timestamps()
  end

  def changeset(reaction, params \\ %{}) do
    reaction
    |> cast(params, [:message_id, :user_id, :emoji])
    |> validate_required([:message_id, :user_id, :emoji])
    |> assoc_constraint(:message)
    |> assoc_constraint(:user)
    |> unique_constraint([:message_id, :user_id, :emoji])
  end
end
