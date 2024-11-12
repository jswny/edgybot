defmodule Edgybot.Reporting.ErrorReporter do
  require Logger

  def handle_event(_, _, meta, _) do
    context = Map.take(meta.job, [:id, :args, :queue, :worker])

    formatted_exception = Exception.format(meta.kind, meta.reason, meta.stacktrace)

    Logger.error("Error in job: #{inspect(context)}\n#{formatted_exception}")
  end
end
