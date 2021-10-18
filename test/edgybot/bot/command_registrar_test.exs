defmodule Edgybot.Bot.CommandRegistrarTest do
  use Edgybot.BotCase

  describe "get_command_module/1" do
    test "returns command module", %{command_module: command_module, command_name: command_name} do
      assert ^command_module = CommandRegistrar.get_command_module(command_name)
    end

    test "returns nil when command module doesn't exist" do
      assert CommandRegistrar.get_command_module("") == nil
    end
  end

  describe "list_commands/1" do
    test "lists commands", %{command_name: command_name} do
      commands = CommandRegistrar.list_commands()
      assert Enum.find(commands, fn command -> command.name == command_name end)
    end
  end
end
