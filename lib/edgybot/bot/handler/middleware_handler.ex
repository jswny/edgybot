defmodule Edgybot.Bot.Handler.MiddlewareHandler do
  @moduledoc false

  alias Edgybot.Bot.Registrar.MiddlewareRegistrar
  alias Nostrum.Struct.Interaction

  def handle_middleware(middleware_list, %Interaction{} = interaction)
      when is_list(middleware_list) do
    middleware_list
    |> Enum.map(&MiddlewareRegistrar.get_module({&1}))
    |> Enum.sort_by(& &1.get_middleware_definition().order)
    |> Enum.reduce(%{}, fn middleware_module, output_map ->
      middleware_name = middleware_module.get_middleware_definition().name
      {:ok, output} = middleware_module.process_interaction(interaction)

      Map.put(output_map, middleware_name, output)
    end)
  end
end
