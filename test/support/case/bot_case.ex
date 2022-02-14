defmodule Edgybot.BotCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Edgybot.Bot.CommandRegistrar
  alias Edgybot.TestUtils

  using do
    quote do
      import Edgybot.Bot.InteractionFixtures
      alias Edgybot.Bot.CommandRegistrar
    end
  end

  setup context do
    if context[:skip_command_registrar] do
      :ok
    else
      start_supervised!(CommandRegistrar)

      if context[:skip_default_command] do
        :ok
      else
        [module_name] = TestUtils.generate_module_names(context, 1)

        defmodule module_name do
          @moduledoc false
          @command_name "command"
          @command_type 1

          def get_command_definitions, do: [%{name: @command_name, type: @command_type}]

          def handle_command([@command_name], @command_type, _options, _interaction), do: :ok
        end

        CommandRegistrar.load_module(module_name)

        [%{name: command_name, type: command_type}] = module_name.get_command_definitions()

        command_definitions = module_name.get_command_definitions()

        [
          command_module: module_name,
          command_name: command_name,
          command_type: command_type,
          command_definitions: command_definitions
        ]
      end
    end
  end
end
