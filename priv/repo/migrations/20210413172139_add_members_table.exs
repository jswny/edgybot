defmodule Edgybot.Repo.Migrations.AddMembersTable do
  use Ecto.Migration

  def change do
    create table("members", primary_key: false) do
      add :guild_id, references(:guilds, type: :bigint), primary_key: true
      add :user_id, references(:users, type: :bigint), primary_key: true

      timestamps()
    end

    create index("members", [:guild_id])
    create index("members", [:user_id])
  end
end
