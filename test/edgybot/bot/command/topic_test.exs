defmodule Edgybot.Bot.Command.TopicTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Topic

  describe "get_command_definitions/0" do
    test "has name and description" do
      assert [%{name: _, description: _}] = Topic.get_command_definitions()
    end
  end
end
