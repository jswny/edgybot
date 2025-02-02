defmodule Edgybot.Bot.Utils do
  @moduledoc false

  alias Nostrum.Cache.Me

  def get_application_id, do: Me.get().id

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
