defmodule Edgybot.Bot.Handler.InteractionErrorHandler do
  @moduledoc false

  alias Edgybot.Workers.InteractionRespondingWorker

  def handle_event(
        [:oban, :job, :exception],
        _measure,
        %{
          job: %{worker: "Edgybot.Workers.InteractionDeferringWorker", args: %{"interaction" => interaction}},
          attempt: attempt
        } = meta,
        _
      ),
      do: maybe_queue_response(attempt, 1, meta, "immediate", interaction, true)

  def handle_event(
        [:oban, :job, :exception],
        _measure,
        %{
          job: %{
            worker: "Edgybot.Workers.InteractionProcessingWorker",
            args: %{"interaction" => interaction, "ephemeral" => ephemeral?}
          },
          attempt: attempt
        } = meta,
        _
      ),
      do: maybe_queue_response(attempt, 3, meta, "followup", interaction, ephemeral?)

  def handle_event(_, _, _, _), do: :ok

  defp maybe_queue_response(attempt, max_attempts, meta, response_type, interaction, ephemeral?) do
    if attempt == max_attempts do
      formatted_exception = Exception.format(meta.kind, meta.reason, meta.stacktrace)

      %{
        interaction: interaction,
        ephemeral: ephemeral?,
        type: response_type,
        exception: formatted_exception
      }
      |> InteractionRespondingWorker.new()
      |> Oban.insert()
    end
  end
end
