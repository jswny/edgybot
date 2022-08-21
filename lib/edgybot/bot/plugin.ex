defmodule Edgybot.Bot.Plugin do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Edgybot.Bot.Middleware

  @type application_command_option_name :: binary()

  @type application_command_option_type_value :: 3..10

  @type application_command_option_description :: binary()

  @type application_command_option_parameter :: %{
          optional(:required) => boolean(),
          name: application_command_option_name(),
          description: application_command_option_description(),
          type: application_command_option_type_value()
        }

  @type application_command_option_type_subcommand :: 1

  @type application_command_option_type_subcommand_group :: 2

  @type application_command_definition_option ::
          %{
            name: application_command_option_name,
            description: binary(),
            type: application_command_option_type_subcommand_group(),
            options: [
              %{
                name: binary(),
                description: application_command_option_description(),
                type: application_command_option_type_subcommand(),
                options: [application_command_option_parameter()]
              }
            ]
          }
          | %{
              name: application_command_option_name(),
              description: application_command_option_description(),
              type: application_command_option_type_subcommand(),
              options: [application_command_option_parameter()]
            }
          | application_command_option_parameter()

  @type interaction_option_value :: binary()

  @type interaction_option ::
          {application_command_option_name(), application_command_option_type_value(),
           interaction_option_value()}

  @type application_command_type :: 1..3

  @type plugin_definition :: %{
          optional(:options) => [application_command_definition_option()],
          optional(:default_permission) => boolean(),
          optional(:middleware) => [Middleware.name()],
          name: binary(),
          description: binary(),
          type: application_command_type()
        }

  @type application_command_name_list :: nonempty_list(binary())

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
              application_command_type,
              [interaction_option],
              Nostrum.Struct.Interaction.t(),
              map()
            ) :: interaction_response()
end
