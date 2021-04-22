defmodule Edgybot.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table("messages", primary_key: false) do
      add :id, :bigint, primary_key: true
      add :user_id, references(:users, type: :bigint), null: false

      timestamps()
    end
  end
end
