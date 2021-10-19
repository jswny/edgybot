defmodule Edgybot.Bot.Command.NickTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Nick

  describe "get_command_definition/1" do
    test "has name and description" do
      assert %{name: _, description: _} = Nick.get_command_definition()
    end
  end
end
