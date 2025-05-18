defmodule Edgybot.Bot.Cache.MessageCacheSlim do
  @moduledoc false
  @behaviour Nostrum.Cache.MessageCache

  use Supervisor

  alias Nostrum.Struct.Message

  @default_limit 100
  @table :discord_message_cache
  @per_channel_limit (
                       caches = Application.compile_env(:nostrum, :caches, %{})

                       opts =
                         case Map.get(caches, :messages) do
                           {_, kw} when is_list(kw) -> kw
                           kw when is_list(kw) -> kw
                           _ -> []
                         end

                       Keyword.get(opts, :per_channel_limit, @default_limit)
                     )

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts)

  @impl true
  def init(_opts) do
    :ets.new(
      @table,
      [:ordered_set, :public, :named_table, read_concurrency: true, write_concurrency: true]
    )

    Supervisor.init([], strategy: :one_for_one)
  end

  @impl true
  def create(payload) do
    payload
    |> Message.to_struct()
    |> insert()
  end

  @impl true
  def update(payload) do
    message = Message.to_struct(payload)
    old = lookup(message.id)
    insert(message)
    {old, message}
  end

  @impl true
  def delete(channel, id), do: take(channel, id)

  @impl true
  def bulk_delete(channel, ids), do: ids |> Enum.map(&take(channel, &1)) |> Enum.reject(&is_nil/1)

  @impl true
  def channel_delete(channel) do
    :ets.select_delete(@table, [{{{channel, :_}, :_}, [], [true]}])
    :ok
  end

  @impl true
  def get(id) do
    id
    |> lookup()
    |> case do
      nil -> {:error, :not_found}
      message -> {:ok, message}
    end
  end

  @impl true
  def get_by_channel(channel, _after_id \\ 0, _before_id \\ :infinity) do
    @table
    |> :ets.match_object({{channel, :_}, :"$1"})
    |> Enum.map(fn {{_, _}, message} -> message end)
    |> Enum.sort_by(& &1.id)
  end

  @impl true
  def get_by_channel_and_author(_, _, _, _), do: raise("not implemented")

  @impl true
  def get_by_author(_, _, _), do: raise("not implemented")

  defp insert(message) do
    :ets.insert(@table, {{message.channel_id, message.id}, message})
    prune(message.channel_id)
    message
  end

  defp lookup(id) do
    case :ets.match_object(@table, {{:_, id}, :"$1"}) do
      [{{_, ^id}, message}] -> message
      _ -> nil
    end
  end

  defp take(channel, id) do
    case :ets.take(@table, {channel, id}) do
      [{{^channel, ^id}, message}] -> message
      _ -> nil
    end
  end

  defp prune(channel) do
    count = :ets.select_count(@table, [{{{channel, :_}, :_}, [], [true]}])

    if count > @per_channel_limit do
      overflow =
        @table
        |> :ets.match({{channel, :"$1"}, :_})
        |> Enum.map(&hd/1)
        |> Enum.sort()
        |> Enum.take(count - @per_channel_limit)

      Enum.each(overflow, &:ets.delete(@table, {channel, &1}))
    end
  end
end
