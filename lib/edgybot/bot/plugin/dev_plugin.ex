defmodule Edgybot.Bot.Plugin.DevPlugin do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Nostrum.Util

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
            },
            %{
              name: "status",
              description: "Check the current status of the bot",
              type: 1
            }
          ]
        },
        metadata: %{
          name: "dev",
          children: [
            %{
              name: "status",
              data: %{
                ephemeral: true
              }
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

  @impl true
  def handle_interaction(["dev", "status"], 1, [], _interaction, _middleware_data) do
    {gateway_url, shard_count} = Util.gateway()
    shard_count = Integer.to_string(shard_count)

    gateway_url_info = "#{Designer.bold("Gateway")}: #{Designer.code_inline(gateway_url)}"
    shard_count_info = "#{Designer.bold("Shards")}: #{Designer.code_inline(shard_count)}"

    shard_latencies = Util.get_all_shard_latencies()

    shard_info =
      Enum.map(shard_latencies, fn {shard_num, latency} ->
        shard_num = Integer.to_string(shard_num)
        latency = Integer.to_string(latency)

        "Shard #{Designer.code_inline(shard_num)} -> #{Designer.code_inline(latency)} ms"
      end)
      |> Enum.join("\n")

    options = [
      title: "Status",
      description: "#{gateway_url_info}\n#{shard_count_info}",
      fields: [%{name: "Shard Latency", value: shard_info}]
    ]

    {:success, options}
  end
end
