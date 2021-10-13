defmodule Edgybot.Bot.Command.Dev do
  @moduledoc false

  alias Edgybot.Bot.Designer

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command_definition do
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
  def handle_command(["dev", "error"], [], _interaction) do
    raise("fake error")
  end

  @impl true
  def handle_command(["dev", "eval"], [{"code", 3, code_string}], _interaction)
      when is_binary(code_string) do
    {result, _binding} = Code.eval_string(code_string)

    result_string =
      result
      |> inspect(pretty: true, width: 0)
      |> Designer.code_block()

    {:success, result_string}
  end
end
