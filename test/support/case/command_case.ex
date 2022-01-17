defmodule Edgybot.CommandCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using opts do
    command_module = opts[:command_module]

    quote do
      describe "get_command_definitions/0" do
        test "has required fields" do
          assert [%{name: _, type: _, description: _}] =
                   unquote(command_module).get_command_definitions()
        end
      end
    end
  end
end
