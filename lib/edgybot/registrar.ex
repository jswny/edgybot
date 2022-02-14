defmodule Edgybot.Registrar do
  @moduledoc false

  defmacro __using__(opts) do
    module_prefix = Keyword.fetch!(opts, :module_prefix)

    quote do
      use Agent
      @behaviour unquote(__MODULE__)

      def start_link(initial_value) do
        Agent.start_link(fn -> load_modules(unquote(module_prefix)) end, name: __MODULE__)
      end

      def get_module(key) when is_tuple(key) do
        Agent.get(__MODULE__, &Map.get(&1, key))
      end

      def list_definitions do
        __MODULE__
        |> Agent.get(& &1)
        |> Enum.flat_map(fn {_key, module} -> get_definitions_from_module(module) end)
        |> Enum.uniq_by(& &1)
      end

      def load_module(module) when is_atom(module) do
        Agent.update(__MODULE__, &add_module(&1, module))
      end

      defp load_modules(module_prefix) when is_atom(module_prefix) do
        {:ok, modules} =
          __MODULE__
          |> Application.get_application()
          |> :application.get_key(:modules)

        modules
        |> Enum.filter(fn module ->
          module
          |> Atom.to_string()
          |> String.starts_with?("#{module_prefix}.")
        end)
        |> Enum.reduce(Map.new(), &add_module(&2, &1))
      end

      defp add_module(modules, module) when is_map(modules) and is_atom(module) do
        module
        |> get_definitions_from_module()
        |> Enum.reduce(modules, fn definition, current_modules ->
          Map.put(current_modules, get_definition_key(definition), module)
        end)
      end
    end
  end

  @type definition :: map()

  @callback get_definitions_from_module(atom()) :: nonempty_list(definition())

  @callback get_definition_key(definition()) :: tuple()
end
