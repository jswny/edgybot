defmodule Edgybot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger
  alias Edgybot.Bot
  alias Edgybot.ObanJobManager
  alias Edgybot.Reporting.ErrorReporter

  @impl true
  def start(_type, _args) do
    children = [
      Bot.Supervisor,
      Edgybot.Repo,
      {Cachex, :processed_string_cache},
      {Oban, Application.fetch_env!(:edgybot, Oban)},
      ObanJobManager
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
end
