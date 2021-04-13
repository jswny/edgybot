defmodule Edgybot.Meta.GuildFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils

  def guild_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{id: random_number()})
  end

  def guild_invalid_attrs, do: %{id: nil}

  def guild_fixture(attrs \\ %{}) do
    {:ok, guild} =
      attrs
      |> Enum.into(guild_valid_attrs())
      |> Meta.create_guild()

    guild
  end
end
