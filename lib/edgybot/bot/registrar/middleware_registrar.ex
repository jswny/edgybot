defmodule Edgybot.Bot.Registrar.MiddlewareRegistrar do
  @moduledoc false

  use Edgybot.Registrar, module_prefix: Edgybot.Bot.Middleware

  @impl true
  def get_definitions_from_module(module) when is_atom(module) do
    [module.get_middleware_definition()]
  end

  @impl true
  def get_definition_key(definition) when is_map(definition) do
    {definition.name}
  end
end
