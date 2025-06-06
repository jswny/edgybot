defmodule Edgybot.Bot.Plugin.TopicPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Nostrum.Api.Channel, as: ChannelApi
  alias Nostrum.Struct.Interaction

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "topic",
          description: "Set the channel topic",
          type: 1,
          options: [
            %{
              name: "content",
              description: "The new channel topic",
              type: 3,
              required: true
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(["topic"], 1, %{"content" => content}, %Interaction{channel_id: channel_id}, _middleware_data)
      when is_binary(content) and is_integer(channel_id) do
    channel_options = %{topic: content}
    {:ok, _channel} = ChannelApi.modify(channel_id, channel_options)

    {:success, "Set the channel topic to #{Designer.code_inline(content)}"}
  end
end
