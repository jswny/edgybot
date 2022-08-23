defmodule Edgybot.Bot.Plugin do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Edgybot.Bot.Middleware
  alias Nostrum.Struct.{ApplicationCommand, Interaction}

  @type plugin_definition :: %{
          optional(:middleware) => [Middleware.name()],
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

  @callback get_plugin_definitions() :: [plugin_definition()]

  @callback handle_interaction(
              application_command_name_list(),
              ApplicationCommand.command_type(),
              [interaction_option],
              Interaction.t(),
              map()
            ) :: interaction_response()
end
