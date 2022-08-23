defmodule Edgybot.Bot.Plugin.DevPlugin do
  @moduledoc false

  alias Edgybot.Bot.Designer

  @behaviour Edgybot.Bot.Plugin

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "dev",
          description: "Developer options",
          type: 1,
          options: [
            %{
              name: "error",
              description: "Purposefully throw an error",
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
      }
    ]
  end

  @impl true
  def handle_interaction(["dev", "error"], 1, [], _interaction, _middleware_data) do
    raise("fake error")
  end

  @impl true
  def handle_interaction(
        ["dev", "eval"],
        1,
        [{"code", 3, code_string}],
        _interaction,
        _middleware_data
      )
      when is_binary(code_string) do
    {result, _binding} = Code.eval_string(code_string)

    result_string =
      result
      |> inspect(pretty: true, width: 0)
      |> Designer.code_block()

    {:success, result_string}
  end
end
