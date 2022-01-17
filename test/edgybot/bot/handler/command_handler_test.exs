defmodule Edgybot.Bot.Handler.CommandHandlerTest do
  use Edgybot.BotCase
  alias Edgybot.Bot.Handler.CommandHandler

  describe "handle_command/2" do
    test "handles interaction", %{command_name: command_name, command_type: command_type} do
      interaction = interaction_fixture(%{data: %{name: command_name, type: command_type}})
      assert :ok = CommandHandler.handle_command(interaction)
    end

    test "skips interaction without matching command name", %{command_type: command_type} do
      interaction = interaction_fixture(%{data: %{name: "", type: command_type}})
      assert :noop = CommandHandler.handle_command(interaction)
    end

    test "skips interaction without matching command type", %{command_name: command_name} do
      interaction = interaction_fixture(%{data: %{name: command_name, type: -1}})
      assert :noop = CommandHandler.handle_command(interaction)
    end
  end
end
