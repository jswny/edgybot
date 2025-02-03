defmodule Edgybot.Bot.Handler.ErrorHandler do
  @moduledoc false

  alias Edgybot.Bot.Designer

  require Logger

  def handle_error(fun, censor) when is_function(fun) and is_boolean(censor) do
    fun.()
  rescue
    e ->
      reason = Exception.message(e)
      stacktrace = __STACKTRACE__

      log_error(reason, stacktrace)

      ErrorTracker.report(e, stacktrace)

      if censor do
        reason = "Internal error"
        {:error, reason}
      else
        {:error, [description: Designer.code_inline(reason), stacktrace: stacktrace]}
      end
  end

  def log_error(reason, stacktrace) when is_list(stacktrace) do
    :error
    |> Exception.format(reason, stacktrace)
    |> Logger.error()
  end
end
