defmodule Edgybot.Bot.Handler.CommandHandlerTest do
  use ExUnit.Case
  alias Edgybot.Bot.CommandRegistrar
  alias Edgybot.Bot.Handler.CommandHandler
  import Edgybot.Bot.InteractionFixtures

  setup do
    start_supervised!(CommandRegistrar)
    :ok
  end

  describe "handle_command/2" do
    test "handles interaction" do
      interaction = interaction_fixture(%{data: %{name: "ping"}})
      assert {:message, _} = CommandHandler.handle_command(interaction)
    end

    test "skips interaction without matching command" do
      interaction = interaction_fixture(%{data: %{name: ""}})
      assert :noop = CommandHandler.handle_command(interaction)
    end
  end
end
