defmodule Edgybot.Bot.Command.Ping do
  @moduledoc false

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command_definition do
    %{
      name: "ping",
      description: "Ping the bot"
    }
  end

  @impl true
  def handle_command(["ping"], [], _interaction) do
    {:success, "Pong!"}
  end
end
