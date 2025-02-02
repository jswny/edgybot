defmodule Edgybot.External.Discord do
  @moduledoc false
  def sanitize_chat_message_name(name, fallback_value) when is_nil(name) and is_binary(fallback_value) do
    cache_result =
      Cachex.fetch(:processed_string_cache, name, fn _key -> {:commit, fallback_value} end)

    case cache_result do
      {:ok, value} -> value
      {:commit, value} -> value
    end
  end

  def sanitize_chat_message_name(name, fallback_value) when is_binary(name) and is_binary(fallback_value) do
    regex = ~r/[a-zA-Z0-9_-]/

    cache_result =
      Cachex.fetch(:processed_string_cache, name, fn key ->
        sanitized =
          key
          |> String.graphemes()
          |> Enum.filter(fn grapheme -> String.match?(grapheme, regex) end)
          |> Enum.join()

        result = if sanitized == "", do: fallback_value, else: sanitized

        {:commit, result}
      end)

    case cache_result do
      {:ok, value} -> value
      {:commit, value} -> value
    end
  end

  def valid_text_message?(message) do
    message.author.bot != true &&
      message.content != nil &&
      message.content != ""
  end
end
