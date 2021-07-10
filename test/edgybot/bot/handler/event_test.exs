defmodule Edgybot.Bot.Handler.EventTest do
  use ExUnit.Case
  alias Edgybot.Bot.Handler.Event
  import Edgybot.TestUtils

  describe "handle_event/2" do
    test "doesn't handle invalid event" do
      event = :FOO
      payload = nil

      assert :noop = Event.handle_event(event, payload)
    end

    test "handles interaction create event" do
      content = build_command("foo")
      event = :INTERACTION_CREATE
      payload = %{id: 123, token: "456", data: %{name: ""}}

      assert :noop = Event.handle_event(event, payload)
    end
  end
end
