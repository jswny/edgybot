defmodule Edgybot.Repo.Migrations.AddAIChannelsTable do
  use Ecto.Migration

  def change do
    create table("ai_channels", primary_key: false) do
      add :channel_id, :bigint, primary_key: true
      add :guild_id, :bigint, null: false
      add :enabled, :boolean, null: false, default: false
      add :model, :text
      add :prompt, :text

      timestamps()
    end
  end
end
