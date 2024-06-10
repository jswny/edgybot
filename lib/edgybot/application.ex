defmodule Edgybot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger
  alias Edgybot.Bot

  @impl true
  def start(_type, _args) do
    children = [
      Bot.Supervisor,
      Edgybot.Repo,
      {Finch, name: Edgybot.Finch},

      # Phoenix
      EdgybotWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:edgybot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Edgybot.PubSub},
      # Start a worker by calling: Edgybot.Worker.start_link(arg)
      # {Edgybot.Worker, arg},
      # Start to serve requests, typically the last entry
      EdgybotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Edgybot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
