defmodule Edgybot.Bot.Plugin do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Edgybot.Bot.Middleware
  alias Nostrum.Struct.{ApplicationCommand, Interaction}

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

  @type interaction_option_value :: binary()

  @type interaction_option ::
          {ApplicationCommand.command_name(), ApplicationCommand.command_option_type(),
           interaction_option_value()}

  @type interaction_response_message :: binary()

  @type interaction_response ::
          {:success, interaction_response_message()}
          | {:warning, interaction_response_message()}
          | {:error, interaction_response_message()}
          | {:success, Designer.options()}
          | {:warning, Designer.options()}
          | {:error, Designer.options()}

  @callback get_plugin_definitions() :: nonempty_list(plugin_definition())

  @callback handle_interaction(
              application_command_name_list(),
              ApplicationCommand.command_type(),
              [interaction_option],
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
    plugin_module.get_plugin_definitions()
    |> Enum.find(nil, fn definition ->
      matching_name? = definition.application_command.name == application_command_name
      matching_type? = definition.application_command.type == application_command_type

      matching_name? && matching_type?
    end)
  end

  def find_option_value(options, name) when is_list(options) and is_binary(name) do
    Enum.find_value(options, nil, fn {current_option_name, _type, value} ->
      if current_option_name == name, do: value
    end)
  end
end
