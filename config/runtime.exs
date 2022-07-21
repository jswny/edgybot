import Config

app_name = :edgybot

get_env_var = fn var_name, default ->
  value = System.get_env(var_name)

  if value == nil || value == "" do
    if default != :none do
      default
    else
      raise """
      Environment variable #{var_name} is missing!
      """
    end
  else
    value
  end
end

maybe_string_to_boolean = fn value ->
  if value == "true" do
    true
  else
    false
  end
end

logflare_enabled =
  "LF_ENABLED"
  |> get_env_var.(false)
  |> maybe_string_to_boolean.()

if logflare_enabled do
  config :logger,
    backends: [:console, LogflareLogger.HttpBackend]

  config :logflare_logger_backend,
    api_key: get_env_var.("LF_API_KEY", nil),
    source_id: get_env_var.("LF_SOURCE_ID", nil)
end

config app_name,
  runtime_env: config_env(),
  memegen_url: get_env_var.("MEMEGEN_URL", "https://api.memegen.link")

config app_name, Edgybot.Repo,
  database: "edgybot_#{config_env()}",
  username: get_env_var.("DATABASE_USERNAME", "postgres"),
  password: get_env_var.("DATABASE_PASSWORD", "postgres"),
  hostname: get_env_var.("DATABASE_HOSTNAME", "localhost")

if config_env() != :test do
  config :nostrum,
    token: get_env_var.("DISCORD_TOKEN", :none)
end
