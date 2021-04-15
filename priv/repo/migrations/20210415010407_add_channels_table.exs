defmodule Edgybot.Repo.Migrations.AddChannelsTable do
  use Ecto.Migration

  def change do
    create table("channels", primary_key: false) do
      add :id, :bigint, primary_key: true
      add :guild_id, references(:guilds, type: :bigint)

      timestamps()
    end
  end
end
