defmodule Edgybot.Bot.Command.ResolverTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Resolver

  describe "match_command/2" do
    test "with command with no arguments returns matched command" do
      parsed_command = [{:string, "foo"}]
      command_definitions = command_definitions_fixture()

      expected = "foo"
      assert {:ok, ^expected} = Resolver.match_command(parsed_command, command_definitions)
    end

    test "with command with static string argument returns matched command" do
      parsed_command = [{:string, "bar"}, {:string, "baz"}]
      command_definitions = command_definitions_fixture()

      expected = "bar"
      assert {:ok, ^expected} = Resolver.match_command(parsed_command, command_definitions)
    end

    test "with command with single string argument returns matched command" do
      parsed_command = [{:string, "bar"}, {:string, "qux"}]
      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected = "bar"
      assert {:ok, ^expected} = Resolver.match_command(parsed_command, command_definitions)
    end

    test "with command with multiple string argument returns matched command" do
      parsed_command = [{:string, "bar"}, {:string, "qux"}, {:string, "quux"}]
      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected = "bar"
      assert {:ok, ^expected} = Resolver.match_command(parsed_command, command_definitions)
    end

    test "with multiple arguments returns matched command" do
      parsed_command = [{:string, "bar"}, {:string, "baz"}, {:string, "qux"}]

      command_definitions =
        command_definitions_fixture(%{"bar" => [:string, {:static_string, "qux"}]})

      expected = "bar"
      assert {:ok, ^expected} = Resolver.match_command(parsed_command, command_definitions)
    end
  end

  defp command_definitions_fixture(args \\ %{}) when is_map(args) do
    default = %{"foo" => [], "bar" => [{:static_string, "baz"}]}
    Map.merge(default, args)
  end
end
