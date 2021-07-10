defmodule Edgybot.Bot.Command.Registrar do
  @moduledoc false

  alias Edgybot.Bot.Command.{Ping, Dev}

  @command_modules [
    Ping,
    Dev
  ]

  def get_command_module(name) do
    Enum.find(@command_modules, fn module -> module.get_command().name == name end)
  end

  def list_commands do
    Enum.map(@command_modules, fn module -> module.get_command() end)
  end
end
