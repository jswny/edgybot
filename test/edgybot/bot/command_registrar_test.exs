defmodule Edgybot.Bot.CommandRegistrarTest do
  use Edgybot.BotCase
  alias Edgybot.TestUtils

  setup context do
    if context[:skip_default_command] do
      [module_name] = generated_module_names = TestUtils.generate_module_names(context, 1)

      defmodule module_name do
        @moduledoc false

        @command_type 1

        def get_command_definitions,
          do: [
            %{name: "command1", type: @command_type},
            %{name: "command2", type: @command_type}
          ]
      end

      [command_module: module_name]
    else
      :ok
    end
  end

  describe "get_command_module/1" do
    test "returns command module", %{
      command_module: command_module,
      command_name: command_name,
      command_type: command_type
    } do
      assert ^command_module = CommandRegistrar.get_command_module(command_name, command_type)
    end

    test "returns nil when command module name doesn't exist", %{command_type: command_type} do
      assert CommandRegistrar.get_command_module("", command_type) == nil
    end

    test "returns nil when command module type doesn't exist", %{command_name: command_name} do
      assert CommandRegistrar.get_command_module(command_name, -1) == nil
    end
  end

  describe "list_command_definitions/1" do
    test "lists command definitions", %{command_name: command_name} do
      commands = CommandRegistrar.list_command_definitions()
      assert Enum.find(commands, fn command -> command.name == command_name end)
    end

    @tag :skip_default_command
    test "does not list duplicate command definitions", %{command_module: command_module} do
      CommandRegistrar.load_command_module(command_module)

      command_definitions = CommandRegistrar.list_command_definitions()

      command_name_1 =
        command_module.get_command_definitions()
        |> Enum.at(0)
        |> Map.get(:name)

      assert 1 =
               Enum.count(command_definitions, fn command_definitions ->
                 command_definitions.name == command_name_1
               end)
    end
  end

  describe "load_command_module/1" do
    @tag :skip_default_command
    test "loads command module with multiple definitions", %{command_module: command_module} do
      CommandRegistrar.load_command_module(command_module)

      for command_definition <- command_module.get_command_definitions() do
        assert ^command_module =
                 CommandRegistrar.get_command_module(
                   command_definition.name,
                   command_definition.type
                 )
      end
    end
  end
end
