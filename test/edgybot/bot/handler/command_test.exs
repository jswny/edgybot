defmodule Edgybot.Bot.Handler.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot
  alias Edgybot.Bot.Handler.Command

  describe "handle_command/2" do
    test "with no command returns error" do
      command_definitions = %{}
      command = Bot.prefix()

      assert {:error, "no command provided"} =
               Command.handle_command(command, command_definitions)
    end

    test "with invalid command name returns error" do
      command_definitions = %{}
      command = build_command("foo")

      assert {:error, "no matching command"} =
               Command.handle_command(command, command_definitions)
    end
  end

  describe "is_command?/1" do
    test "with invalid content returns false" do
      command = "foo"
      result = Command.is_command?(command)
      assert !result
    end

    test "with valid command returns true" do
      command = build_command("foo")
      result = Command.is_command?(command)
      assert result
    end
  end

  defp build_command(command) do
    "#{Bot.prefix()} #{command}"
  end
end
