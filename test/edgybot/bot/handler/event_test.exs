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

    test "doesn't handle message creation from bots" do
      content = "foo"
      event = :MESSAGE_CREATE
      payload = message_payload(content, true)

      assert :noop = Event.handle_event(event, payload)
    end

    test "doesn't handle message creation event with no command" do
      content = "foo"
      event = :MESSAGE_CREATE
      payload = message_payload(content, nil)

      assert :noop = Event.handle_event(event, payload)
    end

    test "handles message creation event" do
      content = build_command("foo")
      event = :MESSAGE_CREATE
      payload = message_payload(content, nil)

      assert {:error, "no matching command"} = Event.handle_event(event, payload)
    end
  end

  defp message_payload(content, bot) do
    %{content: content, author: %{id: 1, bot: bot}}
  end
end
