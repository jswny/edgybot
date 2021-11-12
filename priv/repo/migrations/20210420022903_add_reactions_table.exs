defmodule Edgybot.Repo.Migrations.AddReactionsTable do
  use Ecto.Migration

  def change do
    create table("reactions") do
      add :message_id, references(:messages), null: false
      add :member_id, references(:members), null: false
      add :emote_id, :bigint, null: false

      timestamps()
    end

    create unique_index("reactions", [:message_id, :member_id, :emote_id])
    create index("reactions", [:member_id])
  end
end
