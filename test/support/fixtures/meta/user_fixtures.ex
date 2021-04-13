defmodule Edgybot.Meta.UserFixtures do
  @moduledoc false

  alias Edgybot.Meta
  import Edgybot.TestUtils

  def user_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{id: random_number()})
  end

  def user_invalid_attrs, do: %{id: nil}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(user_valid_attrs())
      |> Meta.create_user()

    user
  end
end
