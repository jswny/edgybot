defmodule Edgybot.Bot.Plugin.PingPlugin do
  @moduledoc false

  @behaviour Edgybot.Bot.Plugin

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "ping",
          description: "Ping the bot",
          type: 1
        }
      }
    ]
  end

  @impl true
  def handle_interaction(["ping"], 1, [], _interaction, _middleware_data) do
    {:success, "Pong!"}
  end
end
