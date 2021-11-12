defmodule Edgybot.Meta.Reaction do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Edgybot.Meta.Snowflake
  alias Edgybot.Meta.{Member, Message}

  schema "reactions" do
    belongs_to(:message, Message)
    belongs_to(:member, Member)

    field(:emote_id, :id)

    timestamps()
  end

  def changeset(reaction, params \\ %{}) do
    reaction
    |> cast(params, [:message_id, :member_id, :emote_id])
    |> validate_required([:message_id, :member_id, :emote_id])
    |> validate_snowflake(:emote_id)
    |> assoc_constraint(:message)
    |> assoc_constraint(:member)
    |> unique_constraint([:message_id, :member_id, :emote_id])
  end
end
