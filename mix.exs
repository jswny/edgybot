defmodule Edgybot.MixProject do
  use Mix.Project

  def project do
    [
      app: :edgybot,
      version: "0.1.0",
      elixir: "~> 1.11",
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
      extra_applications: [:logger],
      mod: {Edgybot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:nostrum, github: "Kraigie/nostrum", ref: "1628880a3e6e45cacc53d2383eb110ff023050e1"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:finch, "~> 0.12"},
      {:logflare_logger_backend, "~> 0.11.0"},
      {:cachex, "~> 3.6"}
    ]
  end

  defp aliases do
    [
      run: "run --no-halt",
      test: ["ecto.create --quiet", "ecto.migrate", "test --no-start"],
      "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
      lint: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
