defmodule Edgybot.Bot.Utils do
  @moduledoc false

  alias Nostrum.Cache.Me

  def get_application_id, do: Me.get().id

  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
