defmodule Edgybot.Bot.Command.PingTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Ping
  import Edgybot.Bot.InteractionFixtures

  describe "get_command/1" do
    test "has name and description" do
      assert %{name: _, description: _} = Ping.get_command()
    end
  end

  describe "handle_interaction/1" do
    test "responds with pong" do
      interaction = interaction_fixture(%{data: %{name: "ping"}})
      assert {:message, "Pong!"} = Ping.handle_interaction(interaction)
    end
  end
end
