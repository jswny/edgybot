defmodule Edgybot.Bot.CommandTest do
  use ExUnit.Case
  alias Edgybot.Bot.Command

  describe "handle_interaction/2" do
    test "passes through interaction" do
      defmodule TestCommand1 do
        def handle_command(_command, _options, interaction) do
          assert interaction.data.name == "command"
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command"
        }
      }

      Command.handle_interaction(TestCommand1, interaction)
    end

    test "handles command with no options" do
      defmodule TestCommand2 do
        def handle_command(["command"], options, _interaction) do
          assert [] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command"
        }
      }

      Command.handle_interaction(TestCommand2, interaction)
    end

    test "handles command with option" do
      defmodule TestCommand3 do
        def handle_command(["command"], options, _interaction) do
          assert [{"option", 3, "value"}] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          options: [
            %{name: "option", type: 3, value: "value"}
          ]
        }
      }

      Command.handle_interaction(TestCommand3, interaction)
    end

    test "handles subcommand with no option" do
      defmodule TestCommand4 do
        def handle_command(["command", "subcommand"], options, _interaction) do
          assert [] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          options: [
            %{
              name: "subcommand"
            }
          ]
        }
      }

      Command.handle_interaction(TestCommand4, interaction)
    end

    test "handles subcommand with option" do
      defmodule TestCommand5 do
        def handle_command(["command", "subcommand"], options, _interaction) do
          assert [{"option", 3, "value"}] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
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

      Command.handle_interaction(TestCommand5, interaction)
    end

    test "handles subcommand group with no options" do
      defmodule TestCommand6 do
        def handle_command(["command", "subcommand group", "subcommand"], options, _interaction) do
          assert [] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
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

      Command.handle_interaction(TestCommand6, interaction)
    end

    test "handles subcommand group with option" do
      defmodule TestCommand7 do
        def handle_command(["command", "subcommand group", "subcommand"], options, _interaction) do
          assert [{"option", 3, "value"}] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
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

      Command.handle_interaction(TestCommand7, interaction)
    end

    test "handles multiple options" do
      defmodule TestCommand8 do
        def handle_command(["command"], options, _interaction) do
          assert [{"option", 3, "value"}, {"option2", 3, "value2"}] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          options: [
            %{name: "option", type: 3, value: "value"},
            %{name: "option2", type: 3, value: "value2"}
          ]
        }
      }

      Command.handle_interaction(TestCommand8, interaction)
    end

    test "handles and converts all option types" do
      defmodule TestCommand9 do
        def handle_command(["command"], options, _interaction) do
          assert [
                   {"option-type-3", 3, "value"},
                   {"option-type-4", 4, 123},
                   {"option-type-5", 5, true},
                   {"option-type-6", 6, %{id: 100, nick: "user"}},
                   {"option-type-7", 7, %{id: 200}},
                   {"option-type-8", 8, %{id: 300}},
                   {"option-type-9", 9, %{id: 300}},
                   {"option-type-10", 10, 1.1}
                 ] = options
        end
      end

      interaction = %Nostrum.Struct.Interaction{
        data: %{
          name: "command",
          options: [
            %{name: "option-type-3", type: 3, value: "value"},
            %{name: "option-type-4", type: 4, value: 123},
            %{name: "option-type-5", type: 5, value: true},
            %{name: "option-type-6", type: 6, value: "100"},
            %{name: "option-type-7", type: 7, value: "200"},
            %{name: "option-type-8", type: 8, value: "300"},
            %{name: "option-type-9", type: 9, value: "300"},
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

      Command.handle_interaction(TestCommand9, interaction)
    end
  end
end
