defmodule Edgybot.Bot.Handler.CommandHandlerTest do
  use Edgybot.BotCase
  alias Edgybot.Bot.Handler.CommandHandler

  describe "handle_command/2" do
    test "handles interaction", %{command_name: command_name} do
      interaction = interaction_fixture(%{data: %{name: command_name}})
      assert :ok = CommandHandler.handle_command(interaction)
    end

    test "skips interaction without matching command" do
      interaction = interaction_fixture(%{data: %{name: ""}})
      assert :noop = CommandHandler.handle_command(interaction)
    end
  end
end
