defmodule Edgybot.Bot.EventConsumer do
  require Logger
  use Nostrum.Consumer
  alias Nostrum.Api

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def child_spec(args) do
    id = "event_consumer_thread_#{args[:thread_number]}"

    %{
      id: id,
      start: {__MODULE__, :start_link, []}
    }
  end
end
