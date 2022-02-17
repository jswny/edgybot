defmodule Edgybot.Bot.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command
  alias Edgybot.TestUtils

  describe "handle_interaction/2" do
    setup context do
      [generated_module_name] = TestUtils.generate_module_names(context, 1)

      [generated_module_name: generated_module_name]
    end

    test "passes through interaction", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(_command, _type, _options, interaction), do: interaction.data.name
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1
        }
      }

      assert "command" = Command.handle_interaction(module_name, interaction)
    end

    test "handles command type", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command"], type, _options, _interaction), do: type
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1
        }
      }

      assert 1 = Command.handle_interaction(module_name, interaction)
    end

    test "handles command with no options", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command"], _type, options, _interaction), do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1
        }
      }

      assert [] = Command.handle_interaction(module_name, interaction)
    end

    test "handles command with option", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command"], _type, options, _interaction), do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{name: "option", type: 3, value: "value"}
          ]
        }
      }

      assert [{"option", 3, "value"}] = Command.handle_interaction(module_name, interaction)
    end

    test "handles subcommand with no option", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command", "subcommand"], _type, options, _interaction), do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{
              name: "subcommand"
            }
          ]
        }
      }

      assert [] = Command.handle_interaction(module_name, interaction)
    end

    test "handles subcommand with option", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command", "subcommand"], _type, options, _interaction), do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{
              name: "subcommand",
              options: [
                %{name: "option", type: 3, value: "value"}
              ]
            }
          ]
        }
      }

      assert [{"option", 3, "value"}] = Command.handle_interaction(module_name, interaction)
    end

    test "handles subcommand group with no options", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(
              ["command", "subcommand group", "subcommand"],
              1,
              options,
              _interaction
            ),
            do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{
              name: "subcommand group",
              options: [
                %{
                  name: "subcommand"
                }
              ]
            }
          ]
        }
      }

      assert [] = Command.handle_interaction(module_name, interaction)
    end

    test "handles subcommand group with option", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(
              ["command", "subcommand group", "subcommand"],
              _type,
              options,
              _interaction
            ),
            do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{
              name: "subcommand group",
              options: [
                %{
                  name: "subcommand",
                  options: [
                    %{name: "option", type: 3, value: "value"}
                  ]
                }
              ]
            }
          ]
        }
      }

      assert [{"option", 3, "value"}] = Command.handle_interaction(module_name, interaction)
    end

    test "handles multiple options", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command"], _type, options, _interaction), do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{name: "option", type: 3, value: "value"},
            %{name: "option2", type: 3, value: "value2"}
          ]
        }
      }

      assert [{"option", 3, "value"}, {"option2", 3, "value2"}] =
               Command.handle_interaction(module_name, interaction)
    end

    test "handles and converts all option types", %{generated_module_name: module_name} do
      defmodule module_name do
        def handle_command(["command"], _type, options, _interaction), do: options
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          type: 1,
          options: [
            %{name: "option-type-3", type: 3, value: "value"},
            %{name: "option-type-4", type: 4, value: 123},
            %{name: "option-type-5", type: 5, value: true},
            %{name: "option-type-6", type: 6, value: 100},
            %{name: "option-type-7", type: 7, value: 200},
            %{name: "option-type-8", type: 8, value: 300},
            %{name: "option-type-9", type: 9, value: 300},
            %{name: "option-type-10", type: 10, value: 1.1}
          ],
          resolved: %{
            channels: %{
              "200": %{
                id: 200
              }
            },
            members: %{
              "100": %{
                nick: "user"
              }
            },
            roles: %{
              "300": %{
                id: 300
              }
            },
            users: %{
              "100": %{
                id: 100
              }
            }
          }
        }
      }

      expected = [
        {"option-type-3", 3, "value"},
        {"option-type-4", 4, 123},
        {"option-type-5", 5, true},
        {"option-type-6", 6, %{id: 100, nick: "user"}},
        {"option-type-7", 7, %{id: 200}},
        {"option-type-8", 8, %{id: 300}},
        {"option-type-9", 9, %{id: 300}},
        {"option-type-10", 10, 1.1}
      ]

      assert ^expected = Command.handle_interaction(module_name, interaction)
    end
  end
end
