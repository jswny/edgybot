defmodule Edgybot.Bot.Handler.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot
  alias Edgybot.Bot.Handler.Command

  describe "is_command?/1" do
    test "with invalid content returns false" do
      content = "foo"
      result = Command.is_command?(content)
      assert !result
    end

    test "with valid content returns true" do
      content = build_command("foo")
      result = Command.is_command?(content)
      assert result
    end
  end

  defp build_command(content) do
    "#{Bot.prefix()} #{content}"
  end
end
