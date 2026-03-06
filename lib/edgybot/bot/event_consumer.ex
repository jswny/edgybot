defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  @behaviour Nostrum.Consumer

  alias Edgybot.Bot.Handler.GuildHandler
  alias Edgybot.Workers.DiscordMesssageEventWorker
  alias Edgybot.Workers.InteractionDeferringWorker

  require Logger

  @impl true
  def handle_event({:GUILD_AVAILABLE, payload, _ws_state}) do
    guild = payload
    GuildHandler.handle_guild_available(guild)
  end

  @impl true
  def handle_event({:MESSAGE_CREATE, payload, _ws_state}) do
    %{
      message: payload
    }
    |> DiscordMesssageEventWorker.new()
    |> Oban.insert()

    payload
  end

  @impl true
  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    %{
      interaction: interaction
    }
    |> InteractionDeferringWorker.new()
    |> Oban.insert()

    interaction
  end

  @impl true
  def handle_event(_event), do: :ok
end
