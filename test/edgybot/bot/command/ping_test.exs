defmodule Edgybot.Bot.Command.PingTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Ping

  describe "get_command_definitions/0" do
    test "has name, type, and description" do
      assert [%{name: _, type: _, description: _}] = Ping.get_command_definitions()
    end
  end

  describe "handle_command/1" do
    test "responds with pong" do
      assert {:success, "Pong!"} = Ping.handle_command(["ping"], 1, [], %{})
    end
  end
end
