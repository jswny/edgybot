Application.ensure_all_started(:ecto)

children = [Edgybot.Repo]
opts = [strategy: :one_for_one, name: Edgybot.TestSupervisor]
Supervisor.start_link(children, opts)

Ecto.Adapters.SQL.Sandbox.mode(Edgybot.Repo, :manual)

ExUnit.start()
