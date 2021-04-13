defmodule Edgybot.Meta.UserFixtures do
  alias Edgybot.Meta

  def user_valid_attrs(attrs \\ %{}) do
    attrs
    |> Enum.into(%{id: 200_317_799_350_927_360})
  end

  def user_invalid_attrs(), do: %{id: nil}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(user_valid_attrs())
      |> Meta.create_user()

    user
  end
end
