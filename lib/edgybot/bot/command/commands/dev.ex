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
    subcommand_name =
      interaction
      |> Map.get(:data)
      |> Map.get(:options)
      |> Enum.at(0)
      |> Map.get(:name)

    case subcommand_name do
      "error" -> _ = raise("fake error")
    end

    {:error, "Unhandled subcommand"}
  end
end
