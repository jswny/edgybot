defmodule Edgybot.Bot.Plugin.SlowPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "slow",
          description: "Modify slowmode for the current channel",
          type: 1,
          options: [
            %{
              name: "enable",
              description: "Turn slowmode on, or adjust the current slowmode",
              type: 1,
              options: [
                %{
                  name: "delay",
                  description: "Length (in seconds) users have to wait between messages",
                  type: 4,
                  required: true
                }
              ]
            },
            %{
              name: "disable",
              description: "Turn slowmode off",
              type: 1
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["slow", "enable"],
        1,
        %{"delay" => delay},
        %Interaction{channel_id: channel_id},
        _middleware_data
      ) do
    lower_bound = 1
    upper_bound = 21_600

    if delay < lower_bound or delay > upper_bound do
      {:warning,
       "Delay must be between #{Designer.code_inline(Integer.to_string(lower_bound))} and #{Designer.code_inline(Integer.to_string(upper_bound))}!"}
    else
      Api.modify_channel!(channel_id, %{rate_limit_per_user: delay})

      {:success, "Sucessfully enabled slow mode with a delay of #{Designer.code_inline(Integer.to_string(delay))}!"}
    end
  end

  @impl true
  def handle_interaction(["slow", "disable"], 1, _options, %Interaction{channel_id: channel_id}, _middleware_data) do
    Api.modify_channel!(channel_id, %{rate_limit_per_user: 0})
    {:success, "Successfully disabled slowmode!"}
  end
end
