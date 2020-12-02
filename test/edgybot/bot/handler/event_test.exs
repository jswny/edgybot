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

    test "doesn't handle message creation event with no command" do
      content = "foo"
      event = :MESSAGE_CREATE
      payload = %{content: content}

      assert :noop = Event.handle_event(event, payload)
    end

    test "handles message creation event" do
      content = build_command("foo")
      event = :MESSAGE_CREATE
      payload = %{content: content}

      assert {:error, "no matching command", ^content} = Event.handle_event(event, payload)
    end
  end
end
