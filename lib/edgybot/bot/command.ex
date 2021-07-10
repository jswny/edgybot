defmodule Edgybot.Bot.Command do
  @moduledoc false

  @callback get_command() :: map

  @callback handle_interaction(map) :: map
end
