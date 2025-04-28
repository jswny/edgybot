defmodule Edgybot.Bot.NostrumDecoders do
  @moduledoc false
  alias Nostrum.Struct.Interaction

  def to_interaction_struct(interaction) when is_map(interaction) do
    interaction
    |> atomise_keys()
    |> Interaction.to_struct()
  end

  defp atomise_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), atomise_keys(v)}
      {k, v} -> {k, atomise_keys(v)}
    end)
  end

  defp atomise_keys(list) when is_list(list), do: Enum.map(list, &atomise_keys/1)
  defp atomise_keys(other), do: other
end
