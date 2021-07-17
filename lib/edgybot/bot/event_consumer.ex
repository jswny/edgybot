defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  require Logger
  use Nostrum.Consumer
  alias Edgybot.Bot.Handler.{ErrorHandler, EventHandler, ResponseHandler}

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  def handle_event({event, payload, _ws_state}) do
    Logger.debug("Received event: #{event}")

    censor_error = Edgybot.runtime_env() == :prod

    ErrorHandler.handle_error(
      fn ->
        EventHandler.handle_event(event, payload)
      end,
      censor_error
    )
    |> ResponseHandler.handle_response(payload)
  end

  @impl true
  def handle_event(_event) do
    ignore("undefined", "event")
  end

  defp ignore(type, thing) do
    Logger.debug("Ignored #{type} #{thing}")
    :noop
  end
end
