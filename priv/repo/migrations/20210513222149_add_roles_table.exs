defmodule Edgybot.Repo.Migrations.AddRolesTable do
  use Ecto.Migration

  def change do
    create table("roles", primary_key: false) do
      add :id, :bigint, primary_key: true
      add :guild_id, references(:guilds, type: :bigint)

      timestamps()
    end

    create index("roles", [:guild_id])
  end
end
