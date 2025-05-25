defmodule Edgybot.Bot.AI.AIChannel do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  schema "ai_channels" do
    field :guild_id, :integer
    field :channel_id, :integer, primary_key: true
    field :enabled, :boolean, default: false
    field :model, :string
    field :prompt, :string

    timestamps()
  end

  def changeset(ai_channel, params \\ %{}) do
    ai_channel
    |> Ecto.Changeset.cast(params, [:guild_id, :channel_id, :enabled, :model, :prompt])
    |> Ecto.Changeset.validate_required([:guild_id, :channel_id])
  end
end
