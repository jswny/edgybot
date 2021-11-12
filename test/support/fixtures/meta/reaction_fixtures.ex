defmodule Edgybot.Meta.ReactionFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils
  import Edgybot.Meta.{MemberFixtures, MessageFixtures}

  def reaction_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      message_id: Map.get(attrs, :message_id) || message_fixture().id,
      member_id: Map.get(attrs, :member_id) || member_fixture().id,
      emote_id: random_number()
    })
  end

  def reaction_invalid_attrs, do: %{}

  def reaction_fixture(attrs \\ %{}) do
    {:ok, reaction} =
      attrs
      |> Enum.into(reaction_valid_attrs())
      |> Meta.create_reaction()

    reaction
  end
end
