defmodule Edgybot.Repo.Migrations.AddEmojiTable do
  use Ecto.Migration

  def change do
    create table("emoji", primary_key: false) do
      add :id, :bigint, primary_key: true

      timestamps()
    end
  end
end
