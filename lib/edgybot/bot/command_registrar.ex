defmodule Edgybot.Bot.CommandRegistrar do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_command_module(command_name) do
    GenServer.call(__MODULE__, {:get_command_module, command_name})
  end

  def list_command_definitions do
    GenServer.call(__MODULE__, :list_command_definitions)
  end

  def load_command_module(command_module) do
    GenServer.cast(__MODULE__, {:load_command_module, command_module})
  end

  @impl true
  def init(_opts) do
    state = %{command_modules: load_command_modules()}
    {:ok, state}
  end

  @impl true
  def handle_call(
        {:get_command_module, command_name},
        _from,
        %{command_modules: command_modules} = state
      ) do
    module = Map.get(command_modules, command_name)
    {:reply, module, state}
  end

  @impl true
  def handle_call(:list_command_definitions, _from, %{command_modules: command_modules} = state) do
    commands =
      command_modules
      |> Enum.flat_map(fn {_command_name, command_module} ->
        command_module.get_command_definitions()
      end)
      |> Enum.uniq()

    {:reply, commands, state}
  end

  @impl true
  def handle_cast(
        {:load_command_module, command_module},
        %{command_modules: command_modules} = state
      ) do
    new_command_modules = add_command_module_definitions(command_modules, command_module)

    new_state = %{state | command_modules: new_command_modules}

    {:noreply, new_state}
  end

  defp load_command_modules do
    {:ok, modules} =
      __MODULE__
      |> Application.get_application()
      |> :application.get_key(:modules)

    modules
    |> Enum.filter(fn module ->
      module
      |> Atom.to_string()
      |> String.starts_with?("Elixir.Edgybot.Bot.Command.")
    end)
    |> Enum.reduce(Map.new(), &add_command_module_definitions(&2, &1))
  end

  defp add_command_module_definitions(command_modules, command_module)
       when is_map(command_modules) and is_atom(command_module) do
    command_module.get_command_definitions()
    |> Enum.reduce(command_modules, fn command_definition, current_command_modules ->
      Map.put(current_command_modules, command_definition.name, command_module)
    end)
  end
end
