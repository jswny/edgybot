defmodule Edgybot.Meta.RoleFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils
  import Edgybot.Meta.GuildFixtures

  def role_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: random_number(),
      guild_id: Map.get(attrs, :guild_id) || guild_fixture().id
    })
  end

  def role_invalid_attrs, do: %{id: nil, guild_id: nil}

  def role_fixture(attrs \\ %{}) do
    {:ok, role} =
      attrs
      |> Enum.into(role_valid_attrs())
      |> Meta.create_role()

    role
  end
end
