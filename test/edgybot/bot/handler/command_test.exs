defmodule Edgybot.Bot.Handler.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot
  alias Edgybot.Bot.Handler.Command
  import Edgybot.TestUtils
  import Edgybot.Bot.InteractionFixtures

  describe "handle_command/2" do
    test "handles interaction" do
      interaction = interaction_fixture(%{data: %{name: "ping"}})
      assert {:message, _} = Command.handle_command(interaction)
    end

    test "skips interaction without matching command" do
      interaction = interaction_fixture(%{data: %{name: ""}})
      assert :noop = Command.handle_command(interaction)
    end
  end
end
