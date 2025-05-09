defmodule Edgybot.Bot.NostrumEncoders do
  @moduledoc false
  alias Edgybot.Bot.NostrumEncoders

  require Protocol

  def struct_to_map_without_struct_key(s), do: s |> Map.from_struct() |> Map.delete(:__struct__)

  def unix_to_iso(nil), do: nil

  def unix_to_iso(epoch) when is_integer(epoch) do
    {:ok, dt} = DateTime.from_unix(epoch)
    DateTime.to_iso8601(dt)
  end

  def unix_to_iso(x), do: x

  defimpl Jason.Encoder, for: Nostrum.Struct.Guild.Member do
    def encode(%{joined_at: _} = m, opts) do
      m
      |> NostrumEncoders.struct_to_map_without_struct_key()
      |> Map.update!(:joined_at, &NostrumEncoders.unix_to_iso/1)
      |> Jason.Encode.map(opts)
    end
  end

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

  @candidates [
    Nostrum.Struct.Interaction,
    Nostrum.Struct.ApplicationCommandInteractionData,
    Nostrum.Struct.ApplicationCommandInteractionDataOption,
    Nostrum.Struct.ApplicationCommandInteractionDataResolved,
    Nostrum.Struct.Component,
    Nostrum.Struct.Component.ActionRow,
    Nostrum.Struct.Component.Button,
    Nostrum.Struct.Component.SelectMenu,
    Nostrum.Struct.Channel,
    Nostrum.Struct.Emoji,
    Nostrum.Struct.Sticker,
    Nostrum.Struct.User
  ]

  for mod <- @candidates do
    with {:module, _} <- Code.ensure_compiled(mod),
         true <- function_exported?(mod, :__struct__, 0),
         impl = Module.concat([Jason.Encoder | Module.split(mod)]),
         false <- Code.ensure_loaded?(impl) do
      Protocol.derive(Jason.Encoder, mod)
    end
  end
end
