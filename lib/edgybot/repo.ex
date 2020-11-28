defmodule Edgybot.Repo do
  use Ecto.Repo,
    otp_app: :edgybot,
    adapter: Ecto.Adapters.Postgres
end
