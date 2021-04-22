defmodule Edgybot.Repo.Migrations.AddReactionsTable do
  use Ecto.Migration

  def change do
    create table("reactions", primary_key: false) do
      add :message_id, references(:messages, type: :bigint), null: false
      add :user_id, references(:users, type: :bigint), null: false
      add :emoji, :string, null: false

      timestamps()
    end

    create unique_index("reactions", [:message_id, :user_id, :emoji])
  end
end
