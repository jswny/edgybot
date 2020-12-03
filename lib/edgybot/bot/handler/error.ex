defmodule Edgybot.Bot.Handler.Error do
  @moduledoc false

  def handle_error(fun) do
    fun.()
  rescue
    e ->
      {:error, Map.get(e, :message) || e, __STACKTRACE__}
  end
end
