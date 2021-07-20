defmodule Edgybot.BotCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Edgybot.Bot.InteractionFixtures
    end
  end

  setup do
    start_supervised!(Edgybot.Bot.CommandRegistrar)
    :ok
  end
end
