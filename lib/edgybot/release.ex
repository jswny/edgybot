defmodule Edgybot.Release do
  @moduledoc """
  Tasks used for execution with releases.
  """

  alias Edgybot.External.Qdrant
  require Logger

  @app :edgybot

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    migrate_qdrant()
  end

  defp migrate_qdrant do
    {:ok, _} = Application.ensure_all_started(:req)
    Logger.info("Migrating Qdrant collections...")

    Qdrant.create_collections()

    Logger.info("Qdrant collections migrated")
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
