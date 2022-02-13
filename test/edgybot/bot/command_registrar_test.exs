defmodule Edgybot.Bot.CommandRegistrarTest do
  use Edgybot.BotCase

  describe "get_definitions_from_module/1" do
    test "gets definitions from module", %{
      command_module: command_module,
      command_definitions: command_definitions
    } do
      ^command_definitions = CommandRegistrar.get_definitions_from_module(command_module)
    end
  end

  describe "get_definition_key/1" do
    test "gets key from module", %{
      command_name: command_name,
      command_type: command_type,
      command_definitions: [command_definition]
    } do
      {^command_name, ^command_type} = CommandRegistrar.get_definition_key(command_definition)
    end
  end
end
