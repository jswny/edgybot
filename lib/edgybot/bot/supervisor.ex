defmodule Edgybot.Bot.Supervisor do
  @moduledoc false

  use Supervisor
  alias Edgybot.Bot

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = generate_event_consumer_children()

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp generate_event_consumer_children() do
    # Generate one child ber thread
    Enum.map(1..System.schedulers_online(), fn thread_number ->
      {Bot.EventConsumer, [thread_number: thread_number]}
    end)
  end
end
