import Config

app_name = :edgybot

get_env_var = fn var_name, default ->
  var = System.get_env(var_name)

  if var == nil || var == "" do
    if default != nil do
      default
    else
      raise """
      Environment variable #{var_name} is missing!
      """
    end
  else
    var
  end
end

config app_name, Repo,
  database: "edgybot_#{config_env()}",
  username: get_env_var.("DATABASE_USERNAME", "postgres"),
  password: get_env_var.("DATABASE_PASSWORD", "postgres"),
  hostname: get_env_var.("DATABASE_HOSTNAME", "localhost")

if config_env() != :test do
  config :nostrum,
    token: get_env_var.("DISCORD_TOKEN", nil)
end
