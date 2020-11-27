import Config

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

config :nostrum,
  token: get_env_var.("DISCORD_TOKEN", nil)
