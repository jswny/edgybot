defmodule Edgybot.Bot.Plugin do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Edgybot.Bot.Middleware
  alias Nostrum.Struct.ApplicationCommand
  alias Nostrum.Struct.Interaction

  @type metadata_data() :: %{
          optional(:ephemeral) => boolean()
        }

  @type metadata :: %{
          optional(:children) => nonempty_list(metadata()),
          optional(:data) => metadata_data(),
          name: binary()
        }

  @type plugin_definition :: %{
          optional(:middleware) => [Middleware.name()],
          optional(:metadata) => metadata(),
          application_command: ApplicationCommand.application_command_map()
        }
  @type application_command_name_list :: nonempty_list(ApplicationCommand.command_name())

  @type interaction_options :: %{optional(binary()) => binary()}

  @type interaction_response_message :: binary()

  @type interaction_response ::
          {:success, interaction_response_message()}
          | {:warning, interaction_response_message()}
          | {:error, interaction_response_message()}
          | {:success, Designer.options()}
          | {:warning, Designer.options()}
          | {:error, Designer.options()}
          | {:message, interaction_response_message()}

  @callback get_plugin_definitions() :: nonempty_list(plugin_definition())

  @callback handle_interaction(
              application_command_name_list(),
              ApplicationCommand.command_type(),
              interaction_options(),
              Interaction.t(),
              map()
            ) :: interaction_response()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__)
    end
  end

  def get_definition_by_key(plugin_module, application_command_name, application_command_type)
      when is_atom(plugin_module) do
    Enum.find(plugin_module.get_plugin_definitions(), nil, fn definition ->
      matching_name? = definition.application_command.name == application_command_name
      matching_type? = definition.application_command.type == application_command_type

      matching_name? && matching_type?
    end)
  end
end
