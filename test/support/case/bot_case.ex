defmodule Edgybot.BotCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Edgybot.Bot.CommandRegistrar

  using do
    quote do
      import Edgybot.Bot.InteractionFixtures
      alias Edgybot.Bot.CommandRegistrar
    end
  end

  defmodule TestCommand do
    @moduledoc false
    @command_name "command"

    def command_name, do: @command_name

    def get_command_definitions, do: [%{name: @command_name}]

    def handle_command([@command_name], _options, _interaction), do: :ok
  end

  setup context do
    skip_command_registrar = Map.get(context, :skip_command_registrar)

    unless skip_command_registrar do
      start_supervised!(CommandRegistrar)

      skip_default_command = Map.get(context, :skip_default_command)

      unless skip_default_command do
        CommandRegistrar.load_command_module(TestCommand)
      end

      {:ok, command_module: TestCommand, command_name: TestCommand.command_name()}
    end
  end
end
