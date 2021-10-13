defmodule Edgybot.Bot.CommandRegistrar do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_command_module(command_name) do
    GenServer.call(__MODULE__, {:get_module, command_name})
  end

  def list_commands do
    GenServer.call(__MODULE__, :list_commands)
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
  def handle_call({:get_module, command_name}, _from, %{command_modules: command_modules} = state) do
    module =
      Enum.find(command_modules, fn module ->
        module.get_command_definition().name == command_name
      end)

    {:reply, module, state}
  end

  @impl true
  def handle_call(:list_commands, _from, %{command_modules: command_modules} = state) do
    commands = Enum.map(command_modules, fn module -> module.get_command_definition() end)

    {:reply, commands, state}
  end

  @impl true
  def handle_cast(
        {:load_command_module, command_module},
        %{command_modules: command_modules} = state
      ) do
    new_command_modules = [command_module | command_modules]
    new_state = %{state | command_modules: new_command_modules}

    {:noreply, new_state}
  end

  defp load_command_modules do
    {:ok, modules} =
      __MODULE__
      |> Application.get_application()
      |> :application.get_key(:modules)

    Enum.filter(modules, fn module ->
      module
      |> Atom.to_string()
      |> String.starts_with?("Elixir.Edgybot.Bot.Command.")
    end)
  end
end
