defmodule Edgybot.Bot.NostrumStructJSONEncoders do
  @moduledoc false

  require Protocol

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

  defimpl Jason.Encoder, for: Nostrum.Struct.Guild.Member do
    def encode(member, opts) do
      member
      |> Map.from_struct()
      |> transform_timestamps()
      |> Jason.Encode.map(opts)
    end

    defp transform_timestamps(%{joined_at: joined_at} = map) when is_integer(joined_at) do
      %{map | joined_at: joined_at |> DateTime.from_unix!() |> DateTime.to_iso8601()}
    end

    defp transform_timestamps(map), do: map
  end

  @nostrum_structs [
    Nostrum.Struct.User,
    Nostrum.Struct.Guild,
    Nostrum.Struct.Channel,
    Nostrum.Struct.Interaction,
    Nostrum.Struct.ApplicationCommandInteractionData,
    Nostrum.Struct.ApplicationCommandInteractionDataOption
  ]

  for module <- @nostrum_structs do
    Protocol.derive(Jason.Encoder, module)
  end
end
