defmodule Edgybot.Bot.Handler.Error do
  @moduledoc false

  def handle_error(fun) do
    fun.()
  rescue
    e ->
      {:error, e.message, __STACKTRACE__}
  end
end
