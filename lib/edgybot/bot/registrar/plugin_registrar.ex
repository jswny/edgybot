defmodule Edgybot.Bot.Registrar.PluginRegistrar do
  @moduledoc false

  use Edgybot.Registrar, module_prefix: Edgybot.Bot.Plugin

  @impl true
  def get_definitions_from_module(module) when is_atom(module) do
    module.get_plugin_definitions()
  end

  @impl true
  def get_definition_key(definition) when is_map(definition) do
    {definition.application_command.name, definition.application_command.type}
  end
end
