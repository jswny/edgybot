defmodule Edgybot.Bot.Command.NickTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Nick

  describe "get_command_definitions/0" do
    test "has name, type, and description" do
      assert [%{name: _, type: _, description: _}] = Nick.get_command_definitions()
    end
  end
end
