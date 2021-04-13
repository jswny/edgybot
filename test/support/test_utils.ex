defmodule Edgybot.TestUtils do
  @moduledoc false

  alias Edgybot.Bot

  def build_command(command) do
    "#{Bot.prefix()} #{command}"
  end

  def random_number(), do: random_number_with_max(1_000_000)

  defp random_number_with_max(max) do
    :rand.uniform(max)
  end
end
