defmodule Edgybot.Workers.InteractionProcessingWorker do
  @moduledoc false
  use Oban.Worker,
    queue: :interaction_process,
    max_attempts: 3,
    tags: ["discord", "interaction"]

  alias Edgybot.Bot.Handler.InteractionHandler
  alias Edgybot.Bot.NostrumDecoders
  alias Edgybot.Workers.InteractionRespondingWorker

  @impl Worker
  def perform(%Oban.Job{
        args: %{
          "interaction" => interaction,
          "parsed_application_command_name_list" => parsed_application_command_name_list,
          "parsed_options" => parsed_options,
          "processed_middleware_data" => processed_middleware_data,
          "ephemeral" => ephemeral?,
          "plugin_module" => plugin_module
        }
      }) do
    interaction = NostrumDecoders.to_interaction_struct(interaction)
    %{data: %{type: interaction_type}} = interaction

    plugin_module = String.to_existing_atom(plugin_module)

    {response_type, response_value} =
      InteractionHandler.process_interaction(
        interaction,
        parsed_application_command_name_list,
        interaction_type,
        parsed_options,
        processed_middleware_data,
        plugin_module
      )

    %{
      interaction: interaction,
      ephemeral: ephemeral?,
      response: %{type: response_type, value: response_value},
      type: "followup"
    }
    |> InteractionRespondingWorker.new()
    |> Oban.insert()

    :ok
  end

  @impl Worker
  def backoff(%Job{attempt: attempt}) do
    attempt
  end
end
