import Config

config :edgybot, Edgybot.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "edgybot_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  # We don't run a server during test. If one is required,
  # you can enable the server option below.
  show_sensitive_data_on_connection_error: true

config :edgybot, EdgybotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Ir5fqiJc0j1E79MMrhZuzgPV62eKNVW1ipXSYt9bEqacSkeFLFuRCNJjmTzWfB3E",
  server: false

config :edgybot, Oban, testing: :inline

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
