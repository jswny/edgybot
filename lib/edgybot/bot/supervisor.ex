defmodule Edgybot.Bot.Supervisor do
  @moduledoc false

  use Supervisor

  alias Edgybot.Bot.EventConsumer
  alias Edgybot.Bot.Registrar.MiddlewareRegistrar
  alias Edgybot.Bot.Registrar.PluginRegistrar

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    bot_options = %{
      consumer: EventConsumer,
      intents: [
        :guild_members,
        :guilds
      ],
      wrapped_token: fn -> System.fetch_env!("DISCORD_TOKEN") end
    }

    children = [
      {Nostrum.Bot, bot_options},
      PluginRegistrar,
      MiddlewareRegistrar
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
