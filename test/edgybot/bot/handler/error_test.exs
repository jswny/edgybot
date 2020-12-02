defmodule Edgybot.Bot.Handler.ErrorTest do
  use ExUnit.Case
  alias Edgybot.Bot.Handler.Error

  describe "handle_error/1" do
    test "converts errors to tuples" do
      fun = fn -> raise "test" end

      assert {:error, "test", _} = Error.handle_error(fun)
    end

    test "passes through non-error" do
      value = {:ok, 5}
      fun = fn -> value end

      assert ^value = Error.handle_error(fun)
    end
  end
end
