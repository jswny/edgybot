defmodule Edgybot.Bot.Command.DevTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command.Dev
  import Edgybot.Bot.InteractionFixtures

  describe "get_command/1" do
    test "has name and description" do
      assert %{name: _, description: _} = Dev.get_command()
    end
  end

  describe "handle_interaction/1" do
    test "with error subcommand raises" do
      interaction_attrs = %{
        data: %{
          name: "dev",
          options: [
            %{
              name: "error"
            }
          ]
        }
      }

      interaction = interaction_fixture(interaction_attrs)

      assert_raise RuntimeError, ~r/.*/, fn ->
        Dev.handle_interaction(interaction)
      end
    end

    test "with eval subcommand evaluates code" do
      interaction_attrs = %{
        data: %{
          name: "dev",
          options: [
            %{
              name: "eval",
              options: [
                %{
                  value: "1 + 1"
                }
              ]
            }
          ]
        }
      }

      interaction = interaction_fixture(interaction_attrs)

      assert {:message, "```2```"} = Dev.handle_interaction(interaction)
    end

    test "with eval subcommand evaluates code and handles results that require inspection" do
      interaction_attrs = %{
        data: %{
          name: "dev",
          options: [
            %{
              name: "eval",
              options: [
                %{
                  value: "[:foo, :bar]"
                }
              ]
            }
          ]
        }
      }

      interaction = interaction_fixture(interaction_attrs)

      assert {:message, "```[:foo, :bar]```"} = Dev.handle_interaction(interaction)
    end
  end
end
