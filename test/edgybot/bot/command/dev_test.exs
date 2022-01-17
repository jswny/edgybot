defmodule Edgybot.Bot.Command.DevTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Dev

  describe "get_command_definitions/0" do
    test "has name, type, and description" do
      assert [%{name: _, type: _, description: _}] = Dev.get_command_definitions()
    end
  end

  describe "handle_command/1" do
    test "with error subcommand raises" do
      assert_raise RuntimeError, ~r/.*/, fn ->
        Dev.handle_command(["dev", "error"], 1, [], %{})
      end
    end

    test "with eval subcommand evaluates code" do
      assert {:success, "```2```"} =
               Dev.handle_command(["dev", "eval"], 1, [{"code", 3, "1 + 1"}], %{})
    end

    test "with eval subcommand evaluates code and handles results that require inspection" do
      assert {:success, "```[:foo,\n :bar]```"} =
               Dev.handle_command(["dev", "eval"], 1, [{"code", 3, "[:foo, :bar]"}], %{})
    end
  end
end
