defmodule Edgybot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  alias Edgybot.Bot
  alias Edgybot.Reporting.ErrorReporter

  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      EdgybotWeb.Telemetry,
      Edgybot.Repo,
      {DNSCluster, query: Application.get_env(:edgybot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Edgybot.PubSub},
      # Start a worker by calling: Edgybot.Worker.start_link(arg)
      # {Edgybot.Worker, arg},
      # Start to serve requests, typically the last entry
      EdgybotWeb.Endpoint,
      Bot.Supervisor,
      Supervisor.child_spec(
        {Cachex, name: :processed_string_cache, expiration: expiration(interval: :timer.hours(24))},
        id: :processed_string_cache
      ),
      {Oban, Application.fetch_env!(:edgybot, Oban)}
    ]

    :ok = Oban.Telemetry.attach_default_logger(level: :debug, encode: false)

    :telemetry.attach(
      "oban-errors",
      [:oban, :job, :exception],
      &ErrorReporter.handle_event/4,
      nil
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Edgybot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EdgybotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
