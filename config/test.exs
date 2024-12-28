import Config

config :edgybot, Edgybot.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true

config :edgybot, Oban, testing: :inline

config :logger, level: :info
