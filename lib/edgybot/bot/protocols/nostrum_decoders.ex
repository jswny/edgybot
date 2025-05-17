defmodule Edgybot.Bot.NostrumDecoders do
  @moduledoc false
  alias Nostrum.Struct.Interaction
  alias Nostrum.Util

  def to_interaction_struct(map) when is_map(map) do
    map
    |> Util.safe_atom_map()
    |> Interaction.to_struct()
  end
end
