defmodule Edgybot.Bot.Command.Topic do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Nostrum.Api

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command do
    %{
      name: "topic",
      description: "Set the channel topic",
      options: [
        %{
          name: "content",
          description: "The new channel topic",
          type: 3,
          required: true
        }
      ]
    }
  end

  @impl true
  def handle_interaction(interaction) do
    channel_id = Map.get(interaction, :channel_id)

    content =
      interaction
      |> Map.get(:data)
      |> Map.get(:options)
      |> Enum.at(0)
      |> Map.get(:value)

    channel_options = %{topic: content}
    {:ok, _channel} = Api.modify_channel(channel_id, channel_options)

    {:success, "Set the channel topic to #{Designer.code_inline(content)}"}
  end
end
