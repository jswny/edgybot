defmodule Edgybot.Bot.Plugin.ModelPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Workers.MessageScrapeWorker

  alias Nostrum.Struct.Interaction

  @impl true
  def get_plugin_definitions do
    # TODO: allow model choices?

    [
      %{
        application_command: %{
          name: "model",
          description: "AI models",
          type: 1,
          options: [
            %{
              name: "create",
              description: "Create a new chat model based on a user",
              type: 1,
              options: [
                %{
                  name: "user",
                  description: "The user to generate a model for",
                  type: 6,
                  required: true
                },
                # TODO: adjust values?
                %{
                  name: "message-count",
                  description: "Number of messages to train on",
                  type: 4,
                  required: false,
                  min_value: 10,
                  max_value: 1000
                }
              ]
            }
          ]
        },
        metadata: %{
          name: "model",
          data: %{
            ephemeral: true
          }
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["model", "create"],
        1,
        [{"user", 6, user} | other_options],
        %Interaction{
          guild_id: guild_id,
          channel_id: channel_id
        },
        _middleware_data
      ) do
    message_count = find_option_value(other_options, "message-count") || 100

    {:ok, job} =
      %{
        type: "fine-tune",
        user_id: user.id,
        guild_id: guild_id,
        channel_id: channel_id,
        num_messages: message_count
      }
      |> MessageScrapeWorker.new()
      |> Oban.insert()

    {:success, "Queued for processing on job ID `#{job.id}`"}
  end
end
