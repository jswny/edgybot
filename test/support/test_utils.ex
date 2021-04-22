defmodule Edgybot.TestUtils do
  @moduledoc false

  alias Edgybot.Bot

  def build_command(command) do
    "#{Bot.prefix()} #{command}"
  end

  def random_number, do: random_number_with_max(1_000_000)

  def random_string(), do: random_string_with_length(10)

  defp random_number_with_max(max) do
    :rand.uniform(max)
  end

  defp random_string_with_length(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
  end
end
