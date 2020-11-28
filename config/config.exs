import Config

config :edgybot,
  ecto_repos: [Edgybot.Repo]

config :porcelain,
  goon_warn_if_missing: false

if config_env() != :prod do
  import_config "#{Mix.env()}.exs"
end
