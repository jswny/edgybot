defmodule Edgybot.Bot.InteractionFixtures do
  @moduledoc false

  import Edgybot.TestUtils

  def interaction_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{id: random_number(), token: random_string()})
  end
end
