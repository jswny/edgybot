defmodule Edgybot.Bot.Handler.InteractionHandler do
  @moduledoc false

  require Logger
  alias Edgybot.Bot.{Command, CommandRegistrar}
  alias Edgybot.Bot.Handler.MiddlewareHandler

  @default_metadata [:metadata]

  def handle_interaction(%{id: id, token: token, data: %{name: name, type: type}} = interaction)
      when is_integer(id) and is_binary(token) and is_binary(name) and is_integer(type) do
    Logger.debug("Handling interaction #{name} (type: #{type})...")

    matching_interaction_module = CommandRegistrar.get_module({name, type})

    case matching_interaction_module do
      nil ->
        :noop

      _ ->
        middleware_data =
          process_middleware_for_interaction(matching_interaction_module, type, interaction)

        Command.handle_interaction(matching_interaction_module, interaction, middleware_data)
    end
  end

  def process_middleware_for_interaction(interaction_module, interaction_type, interaction)
      when is_atom(interaction_module) and is_integer(interaction_type) and is_map(interaction) do
    middleware_list =
      interaction_module.get_command_definitions()
      |> Enum.find(nil, fn definition -> definition.type == interaction_type end)
      |> Map.get(:middleware, [])
      |> Enum.concat(@default_metadata)
      |> Enum.uniq()

    MiddlewareHandler.handle_middleware(middleware_list, interaction)
  end
end
