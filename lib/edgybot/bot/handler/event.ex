defmodule Edgybot.Bot.Handler.Event do
  @moduledoc false

  alias Edgybot.Bot.Handler

  def handle_event(event, payload) when is_atom(event) do
    case event do
      :GUILD_AVAILABLE ->
        {guild} = payload
        Handler.Guild.handle_guild_available(guild)

      :INTERACTION_CREATE ->
        interaction = payload
        Handler.Command.handle_command(interaction)

      _ ->
        :noop
    end
  end
end
