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
  def handle_event({event, payload, _ws_state}) do
    Logger.debug("Received event: #{event}")

    Handler.Error.handle_error(fn ->
      Handler.Event.handle_event(event, payload)
    end)
    |> Handler.Response.handle_response(payload)
    |> log_if_error()
  end

  @impl true
  def handle_event(_event) do
    ignore("undefined", "event")
  end

  defp ignore(type, thing) do
    Logger.debug("Ignored #{type} #{thing}")
    :noop
  end

  defp log_if_error({:error, reason}), do: Logger.error(reason)

  defp log_if_error(result), do: result
end
