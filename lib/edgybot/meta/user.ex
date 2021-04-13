defmodule Edgybot.Meta.User do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}
  schema "users" do
  end
end
