defmodule Edgybot.Bot.Command.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Command

  describe "get_command_definition/1" do
    test "has name and description" do
      assert %{name: _, description: _} = Command.get_command_definition()
    end
  end
end
