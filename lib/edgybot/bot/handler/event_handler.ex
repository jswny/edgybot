defmodule Edgybot.Bot.Handler.EventHandler do
  @moduledoc false

  alias Edgybot.Bot.Handler.{CommandHandler, GuildHandler, ResponseHandler}

  def handle_event(event, payload) when is_atom(event) do
    case event do
      :GUILD_AVAILABLE ->
        guild = payload
        GuildHandler.handle_guild_available(guild)

      :INTERACTION_CREATE ->
        interaction = payload

        interaction
        |> ResponseHandler.defer_interaction_response()
        |> CommandHandler.handle_command()

      _ ->
        :noop
    end
  end
end
