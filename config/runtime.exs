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

get_list_env_var = fn var_name, default ->
  get_env_var.(var_name, default)
  |> String.split(",")
  |> Enum.map(&String.trim/1)
end

get_key_value_env_var = fn var_name, default ->
  get_env_var.(var_name, default)
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn kvp ->
    [name, value] = String.split(kvp, "=")

    %{name: name, value: value}
  end)
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

openai_timeout = String.to_integer(get_env_var.("OPENAI_TIMEOUT", "840000"))
openai_chat_models = get_key_value_env_var.("OPENAI_CHAT_MODELS", "GPT-4o=gpt-4o")
openai_image_models = get_key_value_env_var.("OPENAI_IMAGE_MODELS", "DALL-E-3=dall-e-3")
openai_image_sizes = get_list_env_var.("OPENAI_IMAGE_SIZES", "1024x1024,512x512,256x256")

config app_name,
  runtime_env: config_env(),
  application_command_prefix: get_env_var.("APPLICATION_COMMAND_PREFIX", nil),
  memegen_url: get_env_var.("MEMEGEN_URL", "https://api.memegen.link"),
  archive_hosts_preserve_query: get_list_env_var.("ARCHIVE_HOSTS_PRESERVE_QUERY", ""),
  openai_timeout: openai_timeout,
  openai_chat_models: openai_chat_models,
  openai_image_models: openai_image_models,
  openai_image_sizes: openai_image_sizes

database_url =
  get_env_var.(
    "DATABASE_URL",
    "ecto://postgres:postgres@localhost/edgybot_#{config_env()}"
  )

maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

config app_name, Edgybot.Repo,
  url: database_url,
  socket_options: maybe_ipv6

if config_env() != :test do
  config app_name,
    openai_api_key: get_env_var.("OPENAI_API_KEY", :none)

  config :nostrum,
    token: get_env_var.("DISCORD_TOKEN", :none)
end
