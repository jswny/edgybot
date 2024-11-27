defmodule Edgybot.Bot.Plugin.PingPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "ping",
          description: "Ping the bot",
          type: 1
        },
        metadata: %{
          name: "ping",
          data: %{
            ephemeral: true
          }
        }
      }
    ]
  end

  @impl true
  def handle_interaction(["ping"], 1, _options, _interaction, _middleware_data) do
    {:success, "Pong!"}
  end
end
