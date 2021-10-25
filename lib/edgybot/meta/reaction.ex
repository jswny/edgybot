defmodule Edgybot.Meta.Reaction do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Edgybot.Meta.{Member, Message}

  @primary_key {:id, :id, autogenerate: false}
  schema "reactions" do
    belongs_to(:message, Message)
    belongs_to(:member, Member)
    field(:emoji, :string)

    timestamps()
  end

  def changeset(reaction, params \\ %{}) do
    reaction
    |> cast(params, [:message_id, :member_id, :emoji])
    |> validate_required([:message_id, :member_id, :emoji])
    |> assoc_constraint(:message)
    |> assoc_constraint(:member)
    |> unique_constraint([:message_id, :member_id, :emoji])
  end
end
