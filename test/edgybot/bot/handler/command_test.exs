defmodule Edgybot.Bot.Handler.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot
  alias Edgybot.Bot.Handler.Command

  describe "is_command?/1" do
    test "with invalid message returns false" do
      message = %{content: "foo"}
      result = Command.is_command?(message)
      assert !result
    end

    test "with valid message returns true" do
      message = %{content: "#{Bot.prefix()} foo"}
      result = Command.is_command?(message)
      assert result
    end
  end
end
