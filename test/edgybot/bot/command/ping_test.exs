defmodule Edgybot.Bot.Command.PingTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Ping
  use Edgybot.CommandCase, command_module: Ping

  describe "handle_command/1" do
    test "responds with pong" do
      assert {:success, "Pong!"} = Ping.handle_command(["ping"], 1, [], %{})
    end
  end
end
