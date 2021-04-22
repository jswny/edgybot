defmodule Edgybot.Meta.ReactionFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils
  import Edgybot.Meta.MessageFixtures
  import Edgybot.Meta.UserFixtures

  def reaction_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      message_id: Map.get(attrs, :message_id) || message_fixture().id,
      user_id: Map.get(attrs, :user_id) || user_fixture().id,
      emoji: random_string()
    })
  end

  def reaction_invalid_attrs, do: %{message_id: nil, user_id: nil, emoji: nil}

  def reaction_fixture(attrs \\ %{}) do
    {:ok, reaction} =
      attrs
      |> Enum.into(reaction_valid_attrs())
      |> Meta.create_reaction()

    reaction
  end
end
