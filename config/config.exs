import Config

config :edgybot,
  ecto_repos: [Edgybot.Repo]

import_config "#{Mix.env()}.exs"
