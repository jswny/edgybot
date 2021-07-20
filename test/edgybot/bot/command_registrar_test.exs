defmodule Edgybot.Bot.CommandRegistrarTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Ping
  alias Edgybot.Bot.CommandRegistrar

  @ping_command_name "ping"
  @test_command_name "test-command"

  defmodule TestCommand do
    def get_command, do: %{name: "test-command"}
  end

  setup do
    start_supervised!(CommandRegistrar)
    :ok
  end

  describe "get_command_module/1" do
    test "returns command module" do
      assert Ping = CommandRegistrar.get_command_module(@ping_command_name)
    end
  end

  describe "list_commands/1" do
    test "lists commands" do
      commands = CommandRegistrar.list_commands()
      assert Enum.find(commands, fn command -> command.name == @ping_command_name end)
    end
  end

  describe "load_command_module/1" do
    test "loads a command module" do
      command_module = TestCommand
      CommandRegistrar.load_command_module(command_module)
      assert TestCommand = CommandRegistrar.get_command_module(@test_command_name)
    end
  end
end
