defmodule Edgybot.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table("messages", primary_key: false) do
      add :id, :bigint, primary_key: true
      add :guild_id, :bigint, null: false
      add :user_id, references(:members, column: :user_id, with: [guild_id: :guild_id], name: :messages_member_fkey, type: :bigint, match: :full), null: false

      timestamps()
    end
  end
end
