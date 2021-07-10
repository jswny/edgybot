defmodule Edgybot.Bot.Command do
  @moduledoc false

  @callback get_command() :: %{name: binary(), description: binary()}

  @callback handle_interaction(%{id: integer(), token: binary(), name: binary()}) ::
              {:message, binary()}
end
