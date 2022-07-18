defmodule Edgybot.Bot.Command.Ping do
  @moduledoc false

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command_definitions do
    [
      %{
        name: "ping",
        description: "Ping the bot",
        type: 1
      }
    ]
  end

  @impl true
  def handle_command(["ping"], 1, [], _interaction, _middleware_data) do
    {:success, "Pong!"}
  end
end
