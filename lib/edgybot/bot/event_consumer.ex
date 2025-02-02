defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  use Nostrum.Consumer

  alias Edgybot.Bot.Handler.ErrorHandler
  alias Edgybot.Bot.Handler.EventHandler
  alias Edgybot.Bot.Handler.ResponseHandler
  alias Edgybot.Config

  require Logger

  @impl true
  def handle_event({event, payload, _ws_state}) do
    censor_error = Config.runtime_env() == :prod

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
end
