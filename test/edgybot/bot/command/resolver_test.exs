defmodule Edgybot.Bot.Command.ResolverTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Resolver

  describe "resolve_command/2" do
    test "with no command returns no command provided error" do
      parsed_command = []
      command_definitions = command_definitions_fixture()

      assert {:error, "no command provided"} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with invalid command returns no matching command error" do
      parsed_command = [{:string, "baz"}]
      command_definitions = command_definitions_fixture()

      assert {:error, "no matching command"} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with no arguments returns resolved command and parameters" do
      parsed_command = [{:string, "foo"}]
      command_definitions = command_definitions_fixture()

      expected = "foo"
      assert {:ok, ^expected, []} = Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with static string argument returns resolved command and parameters" do
      parsed_command = [{:string, "bar"}, {:string, "baz"}]
      command_definitions = command_definitions_fixture()

      expected = "bar"

      assert {:ok, ^expected, [{:string, "baz"}]} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with single string argument returns resolved command and parameters" do
      parsed_command = [{:string, "bar"}, {:string, "qux"}]
      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected = "bar"

      assert {:ok, ^expected, [{:string, "qux"}]} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with multiple string arguments returns resolved command and parameters" do
      parsed_command = [{:string, "bar"}, {:string, "baz"}, {:string, "qux"}, {:string, "quux"}]
      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected = "bar"

      assert {:ok, ^expected, [{:string, "baz qux quux"}]} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with static string and string arguments returns resolved command and parameters" do
      parsed_command = [
        {:string, "bar"},
        {:string, "baz"},
        {:string, "qux"},
        {:string, "quux"},
        {:string, "quuz"},
        {:string, "corge"}
      ]

      command_definitions =
        command_definitions_fixture(%{"bar" => [:string, {:static_string, "quux"}, :string]})

      expected = "bar"

      assert {:ok, ^expected, [{:string, "baz qux"}, {:string, "quux"}, {:string, "quuz corge"}]} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end
  end

  defp command_definitions_fixture(args \\ %{}) when is_map(args) do
    default = %{"foo" => [], "bar" => [{:static_string, "baz"}]}
    Map.merge(default, args)
  end
end
