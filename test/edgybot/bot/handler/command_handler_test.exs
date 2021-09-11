defmodule Edgybot.Bot.Handler.CommandHandlerTest do
  use Edgybot.BotCase
  alias Edgybot.Bot.Handler.CommandHandler

  describe "handle_command/2" do
    test "handles interaction" do
      interaction = interaction_fixture(%{data: %{name: "ping"}})
      assert {:success, _} = CommandHandler.handle_command(interaction)
    end

    test "skips interaction without matching command" do
      interaction = interaction_fixture(%{data: %{name: ""}})
      assert :noop = CommandHandler.handle_command(interaction)
    end
  end
end
