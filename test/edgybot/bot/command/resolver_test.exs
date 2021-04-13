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

      expected_command_name = "foo"
      expected_command_args = []

      assert {:ok, ^expected_command_name, ^expected_command_args} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with static string argument returns resolved command and parameters" do
      parsed_command = [{:string, "bar"}, {:string, "baz"}]
      command_definitions = command_definitions_fixture()

      expected_command_name = "bar"
      expected_command_args = [{:string, "baz"}]

      assert {:ok, ^expected_command_name, ^expected_command_args} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with single trailing string argument returns resolved command and parameters" do
      parsed_command = [{:string, "bar"}, {:string, "qux"}]
      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected_command_name = "bar"
      expected_command_args = [{:string, "qux"}]

      assert {:ok, ^expected_command_name, ^expected_command_args} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with multiple trailing string arguments returns resolved command and parameters" do
      parsed_command = [{:string, "bar"}, {:string, "baz"}, {:string, "qux"}, {:string, "quux"}]
      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected_command_name = "bar"
      expected_command_args = [{:string, "baz qux quux"}]

      assert {:ok, ^expected_command_name, ^expected_command_args} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command with arguments and multiple trailing string arguments returns resolved command and parameters" do
      parsed_command = [
        {:string, "bar"},
        {:string, "baz"},
        {:string, "qux"},
        {:string, "quux"},
        {:string, "quuz"}
      ]

      command_definitions =
        command_definitions_fixture(%{"bar" => [{:static_string, "baz"}, :string]})

      expected_command_name = "bar"
      expected_command_args = [{:string, "baz"}, {:string, "qux quux quuz"}]

      assert {:ok, ^expected_command_name, ^expected_command_args} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end

    test "with command multiple trailing string arguments including other arguments returns resolved command and parameters" do
      parsed_command = [
        {:string, "bar"},
        {:string, "<@!123>"},
        {:string, "baz"},
        {:string, "qux"}
      ]

      command_definitions = command_definitions_fixture(%{"bar" => [:string]})

      expected_command_name = "bar"
      expected_command_args = [{:string, "<@!123> baz qux"}]

      assert {:ok, ^expected_command_name, ^expected_command_args} =
               Resolver.resolve_command(parsed_command, command_definitions)
    end
  end

  defp command_definitions_fixture(args \\ %{}) when is_map(args) do
    default = %{"foo" => [], "bar" => [{:static_string, "baz"}]}
    Map.merge(default, args)
  end
end