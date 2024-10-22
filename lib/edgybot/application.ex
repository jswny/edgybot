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
      {Finch, name: FinchPool},
      {Cachex, :processed_string_cache},
      {Oban, Application.fetch_env!(:edgybot, Oban)}
    ]

    :ok = Oban.Telemetry.attach_default_logger(level: :debug)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Edgybot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
