defmodule Edgybot.TestUtils do
  @moduledoc false

  alias Edgybot.Bot

  def build_command(command) do
    "#{Bot.prefix()} #{command}"
  end
end
