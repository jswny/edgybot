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
        },
        %{
          name: "eval",
          description: "Evaluate some Elixir code",
          type: 1,
          options: [
            %{
              name: "code",
              description: "The code to be evaluated",
              type: 3,
              required: true
            }
          ]
        }
      ]
    }
  end

  @impl true
  def handle_interaction(interaction) do
    subcommand_option =
      interaction
      |> Map.get(:data)
      |> Map.get(:options)
      |> Enum.at(0)

    subcommand_name = Map.get(subcommand_option, :name)

    case subcommand_name do
      "error" ->
        _ = raise("fake error")

      "eval" ->
        handle_subcommand_eval(subcommand_option)

      _ ->
        {:error, "Unhandled subcommand"}
    end
  end

  def handle_subcommand_eval(subcommand_option) do
    code_string =
      subcommand_option
      |> Map.get(:options)
      |> Enum.at(0)
      |> Map.get(:value)

    {result, _binding} = Code.eval_string(code_string)
    {:message, "`#{result}`"}
  end
end
