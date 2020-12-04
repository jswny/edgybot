defmodule Edgybot.Bot.Handler.ErrorTest do
  use ExUnit.Case
  alias Edgybot.Bot.Handler.Error

  describe "handle_error/1" do
    test "converts errors to tuples in correct env" do
      fun = fn -> raise "test" end

      assert {:error, "test", _} = Error.handle_error(fun, false)
    end

    test "converts errors to tuples with internal error message and no stacktrace when censoring" do
      fun = fn -> raise "test" end

      assert {:error, "internal error"} = Error.handle_error(fun, true)
    end

    test "passes through non-error" do
      value = {:ok, 5}
      fun = fn -> value end

      assert ^value = Error.handle_error(fun, false)
    end
  end
end
