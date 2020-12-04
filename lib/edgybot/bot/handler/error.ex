defmodule Edgybot.Bot.Handler.Error do
  @moduledoc false

  require Logger

  def handle_error(fun, censor) when is_function(fun) and is_boolean(censor) do
    fun.()
  rescue
    e ->
      reason = Map.get(e, :message) || e
      stacktrace = __STACKTRACE__

      if !censor do
        {:error, reason, __STACKTRACE__}
      else
        log_error(reason, stacktrace)
        reason = "internal error"
        {:error, reason}
      end
  end

  def log_error(reason, stacktrace) when is_list(stacktrace) do
    :error
    |> Exception.format(reason, stacktrace)
    |> Logger.error()
  end
end
