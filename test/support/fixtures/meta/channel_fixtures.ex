defmodule Edgybot.Meta.ChannelFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils
  import Edgybot.Meta.GuildFixtures

  def channel_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: random_number(),
      guild_id: Map.get(attrs, :guild_id) || guild_fixture().id
    })
  end

  def channel_invalid_attrs, do: %{}

  def channel_fixture(attrs \\ %{}) do
    {:ok, channel} =
      attrs
      |> Enum.into(channel_valid_attrs())
      |> Meta.create_channel()

    channel
  end
end
