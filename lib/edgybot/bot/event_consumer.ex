defmodule Edgybot.Bot.EventConsumer do
  @moduledoc """
  Handles all bot events.
  """

  require Logger
  use Nostrum.Consumer
  alias Nostrum.Api
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
  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    event_type = :MESSAGE_CREATE
    Logger.debug("Received event: #{event_type}")

    result = Handler.Message.handle_message_create(message)

    case result do
      {:response, response} -> Api.create_message!(message.channel_id, response)
      :ignore -> :ignore
    end
  end

  @impl true
  def handle_event(event) do
    event_type = elem(event, 0)
    Logger.debug("Ignored event: #{event_type}")
    :noop
  end
end
