defmodule Edgybot.Bot.Handler.EventHandlerTest do
  use Edgybot.BotCase
  alias Edgybot.Bot.Handler.EventHandler

  describe "handle_event/2" do
    test "doesn't handle invalid event" do
      event = :FOO
      payload = nil

      assert :noop = EventHandler.handle_event(event, payload)
    end

    test "handles interaction create event", %{command_name: command_name} do
      event = :INTERACTION_CREATE
      payload = %{id: 123, token: "abc", data: %{name: command_name}}

      assert :ok = EventHandler.handle_event(event, payload)
    end
  end
end
