import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/edgybot start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :edgybot, EdgybotWeb.Endpoint, server: true
end

get_env_var = fn var_name, default ->
  value = System.get_env(var_name)

  if value == nil || value == "" do
    if default == :none do
      raise """
      Environment variable #{var_name} is missing!
      """
    else
      default
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
  var_name
  |> get_env_var.(default)
  |> String.split(",")
  |> Enum.map(&String.trim/1)
end

get_key_value_env_var = fn var_name, default ->
  var_name
  |> get_env_var.(default)
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
  config :logflare_logger_backend,
    api_key: get_env_var.("LF_API_KEY", nil),
    source_id: get_env_var.("LF_SOURCE_ID", nil)

  config :logger,
    backends: [:console, LogflareLogger.HttpBackend]
end

openai_timeout = String.to_integer(get_env_var.("OPENAI_TIMEOUT", "840000"))

openai_chat_models =
  get_key_value_env_var.("OPENAI_CHAT_MODELS", "GPT-4o Mini=gpt-4o-mini")

openai_chat_system_prompt_context_default = """
You are chatting in an existing conversation which may or may not be relevant.
Reference the provided conversation.
If the conversation is not relevant, ignore it and just respond to the user prompt.
If no conversation is provided, respond to the prompt without any context.
When possible, refer to people in the conversation by their names.
Do not mention specifically that you are referring to prior conversations or request more context from the user.
"""

openai_chat_system_prompt_context =
  get_env_var.(
    "OPENAI_CHAT_SYSTEM_PROMPT_CONTEXT",
    openai_chat_system_prompt_context_default
  )

openai_chat_system_prompt_base_default = """
You are a witty assistant chatting with users within a closed group of friends in a Discord server.
Answer concisely and respond authoritatively.
Provide definitive answers and draw conclusions wherever possible.
Provide direct, confident answers.
"""

openai_chat_system_prompt_base =
  get_env_var.(
    "OPENAI_CHAT_SYSTEM_PROMPT_BASE",
    openai_chat_system_prompt_base_default
  )

fal_image_models_generate_default = """
{
  "models": [
    {
      "name": "FLUX Schnell",
      "value": "flux/schnell"
    },
    {
      "name": "FLUX Dev",
      "value": "flux/dev"
    },
    {
      "name": "FLUX Pro v1.1",
      "value": "flux-pro/v1.1",
      "premium": true
    },
    {
      "name": "FLUX Pro v1.1 Ultra",
      "value": "flux-pro/v1.1-ultra",
      "premium": true
    },
    {
      "name": "Stable Diffusion XL Fast Lightning",
      "value": "fast-lightning-sdxl"
    },
    {
      "name": "Stable Diffusion v3.5 Medium",
      "value": "stable-diffusion-v35-medium"
    },
    {
      "name": "Stable Diffusion v3.5 Large",
      "value": "stable-diffusion-v35-large",
      "premium": true
    },
    {
      "name": "Ideogram v2",
      "value": "ideogram/v2",
      "premium": true
    },
    {
      "name": "Recraft v3",
      "value": "recraft-v3",
      "premium": true
    },
    {
      "name": "GPT Image 1",
      "value": "gpt-image-1/text-to-image/byok"
    }
  ]
}
"""

fal_image_models_generate =
  get_env_var.("FAL_IMAGE_MODELS_GENERATE", fal_image_models_generate_default)

fal_image_models_edit_default = """
{
  "models": [
    {
      "name": "GPT Image 1",
      "value": "gpt-image-1/edit-image/byok"
    },
    {
      "name": "FLUX Dev",
      "value": "flux/dev/image-to-image"
    },
    {
      "name": "Ideogram v2 Turbo",
      "value": "ideogram/v2/turbo/remix"
    },
    {
      "name": "Ideogram v2",
      "value": "ideogram/v2/remix",
      "premium": true
    },
    {
      "name": "Stable Diffusion XL Fast Lightning",
      "value": "fast-lightning-sdxl/image-to-image"
    },
    {
      "name": "Stable Diffusion v3 Medium",
      "value": "stable-diffusion-v3-medium/image-to-image"
    }
  ]
}
"""

fal_image_models_edit = get_env_var.("FAL_IMAGE_MODELS_EDIT", fal_image_models_edit_default)

disabled_tools = "CHAT_DISABLED_TOOLS" |> get_list_env_var.("") |> MapSet.new()

config :edgybot, Chat,
  recent_messages_chunk_size: String.to_integer(get_env_var.("CHAT_RECENT_MESSAGES_CHUNK_SIZE", "50")),
  recent_messages_default_count: String.to_integer(get_env_var.("CHAT_RECENT_MESSAGES_DEFAULT_COUNT", "50")),
  disabled_tools: disabled_tools

config :edgybot, Kagi,
  base_url: get_env_var.("KAGI_BASE_URL", "https://kagi.com/api/v0"),
  api_key: get_env_var.("KAGI_API_KEY", nil),
  timeout: String.to_integer(get_env_var.("KAGI_TIMEOUT", "840000"))

config :edgybot, Oban,
  engine: Oban.Engines.Basic,
  queues: [
    default: 10,
    discord_channel_batch: 10,
    discord_message_batch_index: 10
  ],
  plugins: [
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(5)},
    Oban.Plugins.Pruner
  ],
  repo: Edgybot.Repo,
  notifier: Oban.Notifiers.PG

config :edgybot, OpenRouter,
  base_url: get_env_var.("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"),
  api_key: get_env_var.("OPENROUTER_API_KEY", nil),
  timeout: String.to_integer(get_env_var.("OPENROUTER_TIMEOUT", "840000")),
  default_model: get_env_var.("OPENROUTER_DEFAULT_MODEL", "openai/gpt-4o-mini")

config :edgybot,
  runtime_env: config_env(),
  application_command_prefix: get_env_var.("APPLICATION_COMMAND_PREFIX", nil),
  chat_plugin_recent_context_max_size: String.to_integer(get_env_var.("CHAT_PLUGIN_RECENT_CONTEXT_MAX_SIZE", "100")),
  chat_plugin_universal_context_max_size:
    String.to_integer(get_env_var.("CHAT_PLUGIN_UNIVERSAL_CONTEXT_MAX_SIZE", "100")),
  chat_plugin_universal_context_min_score:
    String.to_float(get_env_var.("CHAT_PLUGIN_UNIVERSAL_CONTEXT_MIN_SCORE", "0.3")),
  memegen_url: get_env_var.("MEMEGEN_URL", "https://api.memegen.link"),
  archive_hosts_preserve_query: get_list_env_var.("ARCHIVE_HOSTS_PRESERVE_QUERY", ""),
  openai_base_url: get_env_var.("OPENAI_BASE_URL", "https://api.openai.com"),
  openai_timeout: openai_timeout,
  openai_chat_models: openai_chat_models,
  openai_embedding_model: get_env_var.("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"),
  openai_chat_system_prompt_base: openai_chat_system_prompt_base,
  openai_chat_system_prompt_context: openai_chat_system_prompt_context,
  discord_channel_message_batch_size: 100,
  discord_channel_message_batch_size_index: 10,
  qdrant_api_url: get_env_var.("QDRANT_API_URL", "http://localhost:6333"),
  qdrant_api_key: get_env_var.("QDRANT_API_KEY", nil),
  qdrant_timeout: String.to_integer(get_env_var.("QDRANT_TIMEOUT", "840000")),
  qdrant_collection_discord_messages: get_env_var.("QDRANT_COLLECTION_DISCORD_MESSAGES", "discord_messages"),
  qdrant_collection_discord_messages_vector_size: get_env_var.("QDRANT_COLLECTION_DISCORD_MESSAGES_VECTOR_SIZE", 1536),
  fal_api_url: get_env_var.("FAL_API_URL", "https://queue.fal.run/fal-ai"),
  fal_api_key: get_env_var.("FAL_KEY", nil),
  fal_timeout: String.to_integer(get_env_var.("FAL_TIMEOUT", "840000")),
  fal_status_retry_count: String.to_integer(get_env_var.("FAL_STATUS_RETRY_COUNT", "1200")),
  fal_image_models_generate: fal_image_models_generate,
  fal_image_models_edit: fal_image_models_edit,
  fal_image_models_safety_checker_disable:
    get_list_env_var.("FAL_IMAGE_MODELS_SAFETY_CHECKER_DISABLE", "stable-diffusion, sdxl")

if config_env() != :test do
  config :edgybot,
    openai_api_key: get_env_var.("OPENAI_API_KEY", :none)

  config :nostrum,
    token: get_env_var.("DISCORD_TOKEN", :none),
    ffmpeg: false,
    request_guild_members: true,
    gateway_intents: [
      :guilds,
      :guild_members
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :edgybot, Edgybot.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  config :edgybot, EdgybotWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :edgybot, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :edgybot, EdgybotWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :edgybot, EdgybotWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
