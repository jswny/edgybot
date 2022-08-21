defmodule Edgybot.Bot.Middleware do
  @moduledoc false

  @type name :: atom()

  @callback get_middleware_definition() :: %{name: name(), order: number()}

  @callback(
    process_interaction(Nostrum.Struct.Interaction.t()) :: {:ok, any()},
    {:error, any()}
  )
end
