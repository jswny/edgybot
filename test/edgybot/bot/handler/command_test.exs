defmodule Edgybot.Bot.Handler.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot
  alias Edgybot.Bot.Handler.Command
  import Edgybot.TestUtils

  @context %{}

  describe "handle_command/2" do
    test "with no command returns error" do
      command = Bot.prefix()

      assert {:error, "no command provided"} = Command.handle_command(command, @context)
    end

    test "with invalid command name returns error" do
      command = build_command("foo")

      assert {:error, "no matching command"} = Command.handle_command(command, @context)
    end

    test "with invalid command structure returns error" do
      command = build_command("foo")

      assert {:error, "no matching command"} = Command.handle_command(command, @context)
    end

    test "strips whitespace" do
      command = build_command("   ping   ")

      assert {:message, "Pong!"} = Command.handle_command(command, @context)
    end

    test "with valid ping command returns response" do
      command = build_command("ping")

      assert {:message, "Pong!"} = Command.handle_command(command, @context)
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
end
