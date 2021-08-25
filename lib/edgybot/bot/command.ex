defmodule Edgybot.Bot.Command do
  @moduledoc false

  @typep command_option :: %{name: binary(), description: binary(), type: 3..9}

  @typep option ::
           %{
             name: binary(),
             description: binary(),
             type: 2,
             options: [
               %{
                 name: binary(),
                 description: binary(),
                 type: 1,
                 options: [command_option()]
               }
             ]
           }
           | %{
               name: binary(),
               description: binary(),
               type: 1,
               options: [command_option()]
             }
           | command_option()

  @callback get_command() :: %{
              optional(:options) => [option()],
              optional(:default_permission) => boolean(),
              name: binary(),
              description: binary()
            }

  @callback handle_interaction(Nostrum.Struct.Interaction.t()) ::
              {:message, binary()} | {:error, binary()}
end
