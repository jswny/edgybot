defmodule Edgybot.Meta.MessageFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils
  import Edgybot.Meta.UserFixtures

  def message_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: random_number(),
      user_id: Map.get(attrs, :user_id) || user_fixture().id
    })
  end

  def message_invalid_attrs, do: %{id: nil, user_id: nil}

  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(message_valid_attrs())
      |> Meta.create_message()

    message
  end
end
