defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  require Logger
  use Nostrum.Consumer
  alias Edgybot.Bot.Handler

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def child_spec(opts) do
    id = "event_consumer_thread_#{opts[:thread_number]}"

    %{
      id: id,
      start: {__MODULE__, :start_link, []}
    }
  end

  @impl true
  def handle_event({event, payload, _ws_state}) do
    Logger.debug("Received event: #{event}")

    censor_error = Edgybot.runtime_env() == :prod

    result =
      Handler.Error.handle_error(
        fn ->
          Handler.Event.handle_event(event, payload)
        end,
        censor_error
      )

    Handler.Error.handle_error(
      fn ->
        Handler.Response.handle_response(result, payload)
      end,
      true
    )
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
