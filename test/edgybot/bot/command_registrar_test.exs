defmodule Edgybot.Bot.CommandRegistrarTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Ping
  alias Edgybot.Bot.CommandRegistrar

  @command_name "ping"

  setup do
    start_supervised!(CommandRegistrar)
    :ok
  end

  describe "get_command_module/1" do
    test "returns command module" do
      assert Ping = CommandRegistrar.get_command_module(@command_name)
    end
  end

  describe "list_commands/1" do
    test "lists commands" do
      commands = CommandRegistrar.list_commands()
      assert Enum.find(commands, fn command -> command.name == @command_name end)
    end
  end
end
