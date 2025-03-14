defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  use Nostrum.Consumer

  alias Edgybot.Bot.Handler.GuildHandler
  alias Edgybot.Workers.InteractionDeferringWorker

  require Logger

  @impl true
  def handle_event({:GUILD_AVAILABLE, payload, _ws_state}) do
    guild = payload
    GuildHandler.handle_guild_available(guild)
  end

  def handle_event({:INTERACTION_CREATE, payload, _ws_state}) do
    interaction = payload

    serialized_interaction = Map.from_struct(interaction)

    %{
      interaction: serialized_interaction
    }
    |> InteractionDeferringWorker.new()
    |> Oban.insert()

    interaction
  end

  def handle_event({_, _, _}), do: :noop

  @impl true
  def handle_event(_event) do
    :noop
  end
end
