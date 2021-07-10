defmodule Edgybot.Bot.Command.PingTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Ping

  @interaction %{id: 123, token: "456"}

  describe "get_command/1" do
    test "has name and description" do
      assert %{name: _, description: _} = Ping.get_command()
    end
  end

  describe "handle_interaction/1" do
    test "responds with pong" do
      interaction = Map.put(@interaction, :data, %{name: "ping"})
      assert {:message, "Pong!"} = Ping.handle_interaction(interaction)
    end
  end
end
