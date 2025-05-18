defmodule Edgybot.Bot.Cache.MessageCacheSlimTest do
  use ExUnit.Case, async: false

  alias Edgybot.Bot.Cache.MessageCacheSlim
  alias Nostrum.Struct.Message

  @table :discord_message_cache

  defp per_channel_limit do
    caches = Application.get_env(:nostrum, :caches, %{})

    opts =
      case Map.get(caches, :messages) do
        {_, kw} when is_list(kw) -> kw
        kw when is_list(kw) -> kw
        _ -> []
      end

    Keyword.get(opts, :per_channel_limit, 100)
  end

  defp message_map(id, chan, extra \\ %{}) do
    Map.merge(%{id: id, channel_id: chan}, extra)
  end

  defp sort_ids(list), do: Enum.sort(list)

  setup_all do
    if :ets.whereis(@table) != :undefined, do: :ets.delete(@table)
    start_supervised!(MessageCacheSlim)
    :ok
  end

  setup do
    :ets.delete_all_objects(@table)
    :ok
  end

  test "create stores and returns the message" do
    m = MessageCacheSlim.create(message_map(1, 100))
    assert {:ok, ^m} = MessageCacheSlim.get(1)
  end

  test "update returns {old, new}" do
    MessageCacheSlim.create(message_map(2, 100, %{content: "old"}))
    {old, new} = MessageCacheSlim.update(message_map(2, 100, %{content: "new"}))
    assert old.content == "old"
    assert new.content == "new"
  end

  test "delete removes a single entry" do
    MessageCacheSlim.create(message_map(3, 100))
    assert %Message{id: 3} = MessageCacheSlim.delete(100, 3)
    assert {:error, :not_found} = MessageCacheSlim.get(3)
  end

  test "bulk_delete removes many" do
    ids = Enum.to_list(4..6)
    Enum.each(ids, &MessageCacheSlim.create(message_map(&1, 100)))

    deleted = MessageCacheSlim.bulk_delete(100, ids)
    assert sort_ids(Enum.map(deleted, & &1.id)) == sort_ids(ids)
  end

  test "channel_delete nukes only that channel" do
    MessageCacheSlim.create(message_map(7, 100))
    m2 = MessageCacheSlim.create(message_map(8, 101))

    :ok = MessageCacheSlim.channel_delete(100)

    assert [] == MessageCacheSlim.get_by_channel(100)
    assert {:ok, ^m2} = MessageCacheSlim.get(8)
    assert {:error, :not_found} = MessageCacheSlim.get(7)
  end

  test "get_by_channel returns ascending ids" do
    for id <- [13, 11, 12], do: MessageCacheSlim.create(message_map(id, 102))
    assert [11, 12, 13] == 102 |> MessageCacheSlim.get_by_channel() |> Enum.map(& &1.id)
  end

  test "prune keeps at most the per-channel limit" do
    limit = per_channel_limit()
    for id <- 1..(limit + 5), do: MessageCacheSlim.create(message_map(id, 103))

    kept_ids = 103 |> MessageCacheSlim.get_by_channel() |> Enum.map(& &1.id)
    assert length(kept_ids) == limit
    assert Enum.all?(1..5, &(&1 not in kept_ids))
    assert (limit + 5) in kept_ids
  end

  test "get returns error when absent" do
    assert {:error, :not_found} = MessageCacheSlim.get(999_999)
  end
end
