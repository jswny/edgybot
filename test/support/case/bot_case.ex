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

          def command_name, do: @command_name

          def get_command_definitions, do: [%{name: @command_name}]

          def handle_command([@command_name], _options, _interaction), do: :ok
        end

        CommandRegistrar.load_command_module(module_name)

        [command_module: module_name, command_name: module_name.command_name()]
      end
    end
  end
end
