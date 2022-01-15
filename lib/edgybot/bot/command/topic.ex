defmodule Edgybot.Bot.Command.Topic do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Nostrum.Api

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command_definitions do
    [
      %{
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
    ]
  end

  @impl true
  def handle_command(["topic"], [{"content", 3, content}], %{channel_id: channel_id})
      when is_binary(content) and is_integer(channel_id) do
    channel_options = %{topic: content}
    {:ok, _channel} = Api.modify_channel(channel_id, channel_options)

    {:success, "Set the channel topic to #{Designer.code_inline(content)}"}
  end
end
