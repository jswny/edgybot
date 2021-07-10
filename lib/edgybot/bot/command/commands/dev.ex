defmodule Edgybot.Bot.Command.Dev do
  @moduledoc false

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command do
    %{
      name: "dev",
      description: "Developer options",
      options: [
        %{
          name: "error",
          description: "Purposefully error handling a command",
          type: 1
        }
      ]
    }
  end

  @impl true
  def handle_interaction(interaction) do
    case interaction.data.options[0].name do
      "error" -> 1 / 0
      _ -> :noop
    end
  end
end
