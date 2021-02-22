defmodule Edgybot.Bot.Command.ParserTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Parser

  describe "parse_command/1" do
    test "with empty command returns empty list" do
      command = ""

      expected = []
      assert {:ok, ^expected} = Parser.parse_command(command)
    end

    test "with strings returns parsed strings" do
      command = "foo bar"

      expected = [{:string, "foo"}, {:string, "bar"}]
      assert {:ok, ^expected} = Parser.parse_command(command)
    end

    test "with mentioned users returns parsed mentions" do
      command = "<@!123>"

      expected = [{:mention_user}]
      assert {:ok, ^expected} = Parser.parse_command(command)
    end

    test "with mentioned roles returns parsed mentions" do
      command = "<@&123>"

      expected = [{:mention_role}]
      assert {:ok, ^expected} = Parser.parse_command(command)
    end
  end
end
