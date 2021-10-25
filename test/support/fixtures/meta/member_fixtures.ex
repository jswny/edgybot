defmodule Edgybot.Meta.MemberFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.Meta.{GuildFixtures, UserFixtures}

  def member_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      guild_id: Map.get(attrs, :guild_id) || guild_fixture().id,
      user_id: Map.get(attrs, :user_id) || user_fixture().id
    })
  end

  def member_invalid_attrs, do: %{}

  def member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> Enum.into(member_valid_attrs())
      |> Meta.create_member()

    member
  end
end
