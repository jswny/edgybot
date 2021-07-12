defmodule Edgybot.Bot.Command do
  @moduledoc false

  @callback get_command() :: %{
              optional(:options) => [%{name: binary(), description: binary(), type: 1..9}],
              name: binary(),
              description: binary()
            }

  @callback handle_interaction(Nostrum.Struct.Interaction.t()) ::
              {:message, binary()} | {:error, binary()}
end
