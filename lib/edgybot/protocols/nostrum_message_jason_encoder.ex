defimpl Jason.Encoder, for: Nostrum.Struct.Message do
  def encode(%Nostrum.Struct.Message{} = message, opts) do
    map_representation = %{
      id: message.id,
      channel_id: message.channel_id,
      author: %{
        bot: message.author.bot,
        id: message.author.id
      },
      timestamp: message.timestamp,
      content: message.content
    }

    Jason.Encode.map(map_representation, opts)
  end
end
