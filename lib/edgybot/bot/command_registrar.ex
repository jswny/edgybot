defmodule Edgybot.Bot.CommandRegistrar do
  @moduledoc false

  use GenServer
  alias Edgybot.Bot.Command.{Dev, Ping}

  @command_modules [
    Ping,
    Dev
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_command_module(command_name) do
    GenServer.call(__MODULE__, {:get_module, command_name})
  end

  def list_commands do
    GenServer.call(__MODULE__, :list_commands)
  end

  @impl true
  def init(_opts) do
    state = %{command_modules: @command_modules}
    {:ok, state}
  end

  @impl true
  def handle_call({:get_module, command_name}, _from, %{command_modules: command_modules} = state) do
    module =
      Enum.find(command_modules, fn module -> module.get_command().name == command_name end)

    {:reply, module, state}
  end

  @impl true
  def handle_call(:list_commands, _from, %{command_modules: command_modules} = state) do
    commands = Enum.map(command_modules, fn module -> module.get_command() end)

    {:reply, commands, state}
  end
end
