defmodule Edgybot.Bot.Middleware do
  @moduledoc false

  @callback get_middleware_definition() :: %{name: atom(), order: number()}

  @callback(
    process_interaction(Nostrum.Struct.Interaction.t()) :: {:ok, any()},
    {:error, any()}
  )
end
