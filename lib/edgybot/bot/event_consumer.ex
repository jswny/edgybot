defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  require Logger
  use Nostrum.Consumer
  alias Edgybot.Bot.Handler

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def child_spec(args) do
    id = "event_consumer_thread_#{args[:thread_number]}"

    %{
      id: id,
      start: {__MODULE__, :start_link, []}
    }
  end

  @impl true
  def handle_event({event_type, payload, _ws_state} = event) do
    Logger.debug("Received event: #{event_type}")

    Handler.Event.handle_event(event, payload)
    |> Handler.Response.handle_response()
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
