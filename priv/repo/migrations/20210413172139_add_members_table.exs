defmodule Edgybot.Repo.Migrations.AddMembersTable do
  use Ecto.Migration

  def change do
    create table("members") do
      add :guild_id, references(:guilds), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end

    create unique_index("members", [:guild_id, :user_id])
    create index("members", [:guild_id])
    create index("members", [:user_id])
  end
end
