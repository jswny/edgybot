defmodule Edgybot.External.Discord do
  @moduledoc false
  alias Nostrum.Api.Channel, as: ChannelApi
  alias Nostrum.Cache.MemberCache

  def get_user_sanitized_chat_message_name(guild_id, user_id) do
    case MemberCache.get_with_user(guild_id, user_id) do
      {%{nick: nick}, %{username: username}} -> sanitize_chat_message_name(nick, username)
      nil -> "Unknown"
    end
  end

  defp sanitize_chat_message_name(name, fallback_value) when is_nil(name) and is_binary(fallback_value) do
    cache_result =
      Cachex.fetch(:processed_string_cache, name, fn _key -> {:commit, fallback_value} end)

    case cache_result do
      {:ok, value} -> value
      {:commit, value} -> value
    end
  end

  defp sanitize_chat_message_name(name, fallback_value) when is_binary(name) and is_binary(fallback_value) do
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

  def get_recent_message_chunk(
        guild_id,
        channel_id,
        max_chunk_size,
        message_count_remaining_requested,
        locator \\ {},
        accumulated_message_chunks \\ []
      )

  def get_recent_message_chunk(
        _guild_id,
        _channel_id,
        _max_chunk_size,
        message_count_remaining_requested,
        _locator,
        accumulated_message_chunks
      )
      when message_count_remaining_requested <= 0 do
    List.flatten(accumulated_message_chunks)
  end

  def get_recent_message_chunk(
        guild_id,
        channel_id,
        max_chunk_size,
        message_count_remaining_requested,
        locator,
        accumulated_message_chunks
      ) do
    chunk_size = min(message_count_remaining_requested, max_chunk_size)

    {:ok, messages} = ChannelApi.messages(channel_id, chunk_size, locator)

    message_chunk =
      messages
      |> Enum.map(fn message ->
        sanitized_nick = get_user_sanitized_chat_message_name(guild_id, message.author.id)
        %{id: message.id, name: sanitized_nick, content: message.content}
      end)
      |> Enum.reverse()

    {message_count_remaining_requested, earliest_message_id} =
      if message_chunk == [] do
        {0, nil}
      else
        earliest_message_id = List.first(message_chunk).id
        message_count = Enum.count(message_chunk)
        {message_count_remaining_requested - message_count, earliest_message_id}
      end

    get_recent_message_chunk(
      guild_id,
      channel_id,
      max_chunk_size,
      message_count_remaining_requested,
      {:before, earliest_message_id},
      [message_chunk | accumulated_message_chunks]
    )
  end
end
