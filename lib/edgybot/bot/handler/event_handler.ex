defmodule Edgybot.Bot.Handler.EventHandler do
  @moduledoc false

  alias Edgybot.Bot.Handler.{GuildHandler, InteractionHandler, ResponseHandler}

  def handle_event(event, payload) when is_atom(event) do
    case event do
      :GUILD_AVAILABLE ->
        guild = payload
        GuildHandler.handle_guild_available(guild)

      :INTERACTION_CREATE ->
        interaction = payload

        interaction
        |> ResponseHandler.defer_interaction_response()
        |> InteractionHandler.handle_interaction()

      _ ->
        :noop
    end
  end
end
