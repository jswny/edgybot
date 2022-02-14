defmodule Edgybot.RegistrarCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  defmodule TestRegistrar do
    @moduledoc false

    use Edgybot.Registrar, module_prefix: Elixir.Edgybot.RegistrarCase

    def get_definitions_from_module(module), do: module.definitions()

    def get_definition_key(%{id: id}), do: {id}

    def definitions, do: [%{id: 1}, %{id: 2}, %{id: 2}]
  end

  setup do
    start_supervised!(TestRegistrar)

    [registrar: TestRegistrar]
  end
end
