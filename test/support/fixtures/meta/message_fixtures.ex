defmodule Edgybot.Meta.MessageFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils
  import Edgybot.Meta.{MemberFixtures, ChannelFixtures}

  def message_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: random_number(),
      member_id: Map.get(attrs, :member_id) || member_fixture().id,
      channel_id: Map.get(attrs, :channel_id) || channel_fixture().id
    })
  end

  def message_invalid_attrs, do: %{id: nil, member_id: nil, channel_id: nil}

  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(message_valid_attrs())
      |> Meta.create_message()

    message
  end
end
