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
openai_chat_models = get_key_value_env_var.("OPENAI_CHAT_MODELS", "GPT-4o Mini=gpt-4o-mini")
openai_image_models = get_key_value_env_var.("OPENAI_IMAGE_MODELS", "DALL-E-3=dall-e-3")
openai_image_sizes = get_list_env_var.("OPENAI_IMAGE_SIZES", "1024x1024,512x512,256x256")

openai_chat_system_prompt_context_default = """
Reference the provided conversation.
When possible, refer to people in the conversation by their names.
If no conversation is provided, respond to the prompt without any context.
If the conversation is not relevant, ignore it.
"""

openai_chat_system_prompt_context =
  get_env_var.(
    "OPENAI_CHAT_SYSTEM_PROMPT_CONTEXT",
    openai_chat_system_prompt_context_default
  )

openai_chat_system_prompt_base_default = """
Be sarcastic and witty.
Answer concisely.
Provide definitive answers and draw conclusions wherever possible.
"""

openai_chat_system_prompt_base =
  get_env_var.(
    "OPENAI_CHAT_SYSTEM_PROMPT_BASE",
    openai_chat_system_prompt_base_default
  )

config app_name,
  runtime_env: config_env(),
  application_command_prefix: get_env_var.("APPLICATION_COMMAND_PREFIX", nil),
  chat_plugin_max_context_size:
    String.to_integer(get_env_var.("CHAT_PLUGIN_MAX_CONTEXT_SIZE", "100")),
  memegen_url: get_env_var.("MEMEGEN_URL", "https://api.memegen.link"),
  archive_hosts_preserve_query: get_list_env_var.("ARCHIVE_HOSTS_PRESERVE_QUERY", ""),
  openai_base_url: get_env_var.("OPENAI_BASE_URL", "https://api.openai.com"),
  openai_timeout: openai_timeout,
  openai_chat_models: openai_chat_models,
  openai_image_models: openai_image_models,
  openai_embedding_model: get_env_var.("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"),
  openai_image_sizes: openai_image_sizes,
  openai_chat_system_prompt_base: openai_chat_system_prompt_base,
  openai_chat_system_prompt_context: openai_chat_system_prompt_context,
  index_discord_message_batch_size: 10,
  qdrant_api_url: get_env_var.("QDRANT_API_URL", "http://localhost:6333"),
  qdrant_api_key: get_env_var.("QDRANT_API_KEY", nil),
  qdrant_timeout: String.to_integer(get_env_var.("QDRANT_TIMEOUT", "840000")),
  qdrant_collection_discord_messages:
    get_env_var.("QDRANT_COLLECTION_DISCORD_MESSAGES", "discord_messages"),
  qdrant_collection_discord_messages_vector_size:
    get_env_var.("QDRANT_COLLECTION_DISCORD_MESSAGES_VECTOR_SIZE", 1536)

database_url =
  get_env_var.(
    "DATABASE_URL",
    "ecto://postgres:postgres@localhost/edgybot_#{config_env()}"
  )

maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

config app_name, Edgybot.Repo,
  url: database_url,
  socket_options: maybe_ipv6

config :edgybot, Oban,
  engine: Oban.Engines.Basic,
  queues: [
    default: 10,
    index_discord_channel: 10
  ],
  repo: Edgybot.Repo

if config_env() != :test do
  config app_name,
    openai_api_key: get_env_var.("OPENAI_API_KEY", :none)

  config :nostrum,
    token: get_env_var.("DISCORD_TOKEN", :none),
    ffmpeg: false
end
