defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  use Nostrum.Consumer

  alias Edgybot.Bot.Handler.ErrorHandler
  alias Edgybot.Bot.Handler.EventHandler
  alias Edgybot.Bot.Handler.ResponseHandler

  require Logger

  @impl true
  def handle_event({event, payload, _ws_state}) do
    runtime_env = Application.get_env(:edgybot, :runtime_env)
    censor_error = runtime_env == :prod

    generate_error_context(event, payload)

    fn ->
      EventHandler.handle_event(event, payload)
    end
    |> ErrorHandler.handle_error(censor_error)
    |> ResponseHandler.handle_response(payload)
  end

  @impl true
  def handle_event(_event) do
    :noop
  end

  defp generate_error_context(event, payload) do
    context = %{
      event: event,
      interaction_id: get_in(payload, [Access.key(:id, nil)]),
      interaction_type: get_in(payload, [Access.key(:type, nil)]),
      guild_id: get_in(payload, [Access.key(:guild_id, nil)]),
      channel_id: get_in(payload, [Access.key(:channel_id, nil)]),
      channel_name: get_in(payload, [Access.key(:channel, %{}), Access.key(:name, nil)]),
      user_id: get_in(payload, [Access.key(:user, %{}), Access.key(:id, nil)]),
      username: get_in(payload, [Access.key(:user, %{}), Access.key(:username, nil)]),
      interaction_name: get_in(payload, [Access.key(:data, %{}), Access.key(:name, nil)])
    }

    ErrorTracker.set_context(context)
  end
end
