defmodule Edgybot.Bot.Supervisor do
  @moduledoc false

  use Supervisor
  alias Edgybot.Bot

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Bot.EventConsumer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
