defmodule Edgybot.MixProject do
  use Mix.Project

  def project do
    [
      app: :edgybot,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Edgybot.Application, []},
      included_applications: [:nostrum],
      extra_applications: [:certifi, :gun, :inets, :jason, :logger, :mime]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:nostrum, github: "Kraigie/nostrum", ref: "1628880a3e6e45cacc53d2383eb110ff023050e1", runtime: false},
      {:gun, "~> 2.0.1"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19.2"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5.0"},
      {:cachex, "~> 4.0"},
      {:oban, "~> 2.19"},
      {:styler, "~> 1.3", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.7.19"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:ecto_psql_extras, "~> 0.8"},
      {:oban_web, "~> 2.11"},
      {:error_tracker, "~> 0.5"}
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict", "dialyzer"],
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --no-start"],
      # test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind edgybot", "esbuild edgybot"],
      "assets.deploy": [
        "tailwind edgybot --minify",
        "esbuild edgybot --minify",
        "phx.digest"
      ]
    ]
  end
end
