defmodule Edgybot.Bot.Utils do
  @moduledoc false

  alias Nostrum.Cache.Me

  def get_application_id, do: Me.get().id
end
