defmodule Edgybot.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table("messages", primary_key: false) do
      add :id, :bigint, primary_key: true
      add :member_id, references(:members), null: false
      add :channel_id, references(:channels), null: false

      timestamps()
    end

    create index("messages", [:member_id])
    create index("messages", [:channel_id])
  end
end
