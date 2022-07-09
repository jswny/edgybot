defmodule Edgybot.Bot.Handler.EventHandler do
  @moduledoc false

  alias Edgybot.Bot.Handler.{CommandHandler, GuildHandler}

  def handle_event(event, payload) when is_atom(event) do
    case event do
      :GUILD_AVAILABLE ->
        guild = payload
        GuildHandler.handle_guild_available(guild)

      :INTERACTION_CREATE ->
        interaction = payload
        CommandHandler.handle_command(interaction)

      _ ->
        :noop
    end
  end
end
