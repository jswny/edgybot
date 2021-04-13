defmodule Edgybot.Repo.Migrations.AddGuildsTable do
  use Ecto.Migration

  def change do
    create table("guilds", primary_key: false) do
      add :id, :bigint, primary_key: true

      timestamps()
    end
  end
end
