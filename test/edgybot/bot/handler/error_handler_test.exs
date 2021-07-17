defmodule Edgybot.Bot.Handler.ErrorHandlerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Edgybot.Bot.Handler.ErrorHandler

  describe "handle_error/1" do
    test "converts errors to tuples when not censoring" do
      fun = fn -> raise "test" end

      assert {:error, "test", _} = ErrorHandler.handle_error(fun, false)
    end

    test "converts errors with no message to tuples when not censoring" do
      fun = fn -> "#{{:string, "foo"}}" end

      expected_message =
        ~s/protocol String.Chars not implemented for {:string, "foo"} of type / <>
          ~s/Tuple. This protocol is implemented for the following type(s):/

      assert {:error, actual_message, _} = ErrorHandler.handle_error(fun, false)
      assert actual_message =~ expected_message
    end

    test "logs errors" do
      fun = fn -> raise "test" end

      assert capture_log(fn ->
               assert {:error, "internal error"} = ErrorHandler.handle_error(fun, true)
             end) =~ "Erlang error: \"test\""
    end

    test "passes through non-error" do
      value = {:ok, 5}
      fun = fn -> value end

      assert ^value = ErrorHandler.handle_error(fun, false)
    end
  end
end
