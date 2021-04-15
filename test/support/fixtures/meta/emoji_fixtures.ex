defmodule Edgybot.Meta.EmojiFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils

  def emoji_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{id: Integer.to_string(random_number())})
  end

  def emoji_invalid_attrs, do: %{id: nil}

  def emoji_fixture(attrs \\ %{}) do
    {:ok, emoji} =
      attrs
      |> Enum.into(emoji_valid_attrs())
      |> Meta.create_emoji()

    emoji
  end
end
