Logger.configure(level: Application.get_env(:logger, :level))

{:ok, _} = Application.ensure_all_started(:plug)
{:ok, _} = Application.ensure_all_started(:phoenix_pubsub)

children = [
  EdgybotWeb.Telemetry,
  Edgybot.Repo,
  {DNSCluster, query: Application.get_env(:edgybot, :dns_cluster_query) || :ignore},
  {Phoenix.PubSub, name: Edgybot.PubSub},
  EdgybotWeb.Endpoint
]

opts = [strategy: :one_for_one, name: Edgybot.TestSupervisor]
Supervisor.start_link(children, opts)

Ecto.Adapters.SQL.Sandbox.mode(Edgybot.Repo, :manual)

ExUnit.start()
