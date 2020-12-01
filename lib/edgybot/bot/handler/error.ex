defmodule Edgybot.Bot.Handler.Error do
  @moduledoc false

  def handle_error(fun) do
    try do
      fun.()
    rescue
      e ->
        nil
    end
  end
end
