defmodule Edgybot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger
  alias Edgybot.Bot.EventConsumer

  @impl true
  def start(_type, _args) do
    Logger.info("Starting...")

    children = generate_event_consumer_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Edgybot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp generate_event_consumer_children() do
    # Generate one child ber thread
    Enum.map(1..System.schedulers_online(), fn thread_number ->
      {EventConsumer, [thread_number: thread_number]}
    end)
  end
end
