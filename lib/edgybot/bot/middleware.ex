defmodule Edgybot.Bot.Middleware do
  @moduledoc false

  alias Nostrum.Struct.Interaction

  @type name :: atom()

  @callback get_middleware_definition() :: %{name: name(), order: number()}

  @callback(
    process_interaction(Interaction.t()) :: {:ok, any()},
    {:error, any()}
  )
end
