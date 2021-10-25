defmodule Edgybot.Repo.Migrations.AddReactionsTable do
  use Ecto.Migration

  def change do
    create table("reactions", primary_key: false) do
      add :message_id, references(:messages, type: :bigint), null: false
      add :member_id, references(:members), null: false
      add :emoji, :string, null: false

      timestamps()
    end

    create unique_index("reactions", [:message_id, :member_id, :emoji])
    create index("reactions", [:member_id])
  end
end
