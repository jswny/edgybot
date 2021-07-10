defmodule Edgybot.Bot.Command.Ping do
  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command() do
    %{
      name: "ping",
      description: "check for alive-ness"
    }
  end

  @impl true
  def handle_interaction(_interaction) do
    {:message, "Pong!"}
  end
end
