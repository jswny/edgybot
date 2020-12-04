defmodule Edgybot do
  @moduledoc false

  def runtime_env do
    __MODULE__
    |> Application.get_application()
    |> Application.fetch_env!(:runtime_env)
  end
end
