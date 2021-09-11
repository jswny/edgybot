defmodule Edgybot.Bot.Handler.ErrorHandlerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Edgybot.Bot.Handler.ErrorHandler

  defp error_fun, do: raise("test")

  describe "handle_error/1" do
    test "converts errors to responses when not censoring" do
      assert {:error, [description: "``test``", stacktrace: _]} =
               ErrorHandler.handle_error(&error_fun/0, false)
    end

    test "always logs errors" do
      assert capture_log(fn ->
               ErrorHandler.handle_error(&error_fun/0, true)
             end) =~ "Erlang error: \"test\""

      assert capture_log(fn ->
               ErrorHandler.handle_error(&error_fun/0, false)
             end) =~ "Erlang error: \"test\""
    end

    test "passes through non-error" do
      value = {:ok, 5}
      fun = fn -> value end

      assert ^value = ErrorHandler.handle_error(fun, false)
    end
  end
end
