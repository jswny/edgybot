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

config app_name,
  runtime_env: config_env(),
  silent_mode: get_env_var.("SILENT_MODE", false)

config app_name, Edgybot.Repo,
  database: "edgybot_#{config_env()}",
  username: get_env_var.("DATABASE_USERNAME", "postgres"),
  password: get_env_var.("DATABASE_PASSWORD", "postgres"),
  hostname: get_env_var.("DATABASE_HOSTNAME", "localhost")

if config_env() != :test do
  config :nostrum,
    token: get_env_var.("DISCORD_TOKEN", :none)
end
