defmodule Edgybot.Bot.Handler.Error do
  @moduledoc false

  require Logger

  def handle_error(fun, censor) when is_function(fun) and is_boolean(censor) do
    fun.()
  rescue
    e ->
      reason = Exception.message(e)
      stacktrace = __STACKTRACE__

      log_error(reason, stacktrace)

      if censor do
        reason = "internal error"
        {:error, reason}
      else
        {:error, reason, __STACKTRACE__}
      end
  end

  def log_error(reason, stacktrace) when is_list(stacktrace) do
    :error
    |> Exception.format(reason, stacktrace)
    |> Logger.error()
  end
end
