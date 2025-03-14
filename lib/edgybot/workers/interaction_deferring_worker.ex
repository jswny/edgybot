defmodule Edgybot.Workers.InteractionDeferringWorker do
  @moduledoc false
  use Oban.Worker,
    queue: :interaction_defer,
    max_attempts: 1,
    tags: ["discord", "interaction"]

  alias Edgybot.Bot.Handler.InteractionHandler
  alias Edgybot.Bot.Handler.ResponseHandler
  alias Edgybot.Workers.InteractionProcessingWorker

  @impl Worker
  def perform(%Oban.Job{args: %{"interaction" => interaction}}) do
    plugin_match_result =
      interaction
      |> InteractionHandler.transform_interaction_name()
      |> InteractionHandler.match_plugin_module()

    case plugin_match_result do
      {:ok, interaction, matched_plugin_module} ->
        {parsed_application_command_name_list, parsed_options} =
          InteractionHandler.parse_interaction(interaction)

        application_command_metadata =
          InteractionHandler.get_application_command_metadata_for_interaction(
            interaction,
            matched_plugin_module,
            parsed_application_command_name_list
          )

        ephemeral? = InteractionHandler.ephemeral?(application_command_metadata, parsed_options)

        {:ok} = ResponseHandler.defer_response(interaction, ephemeral?)

        processed_middleware_data =
          InteractionHandler.process_middleware_for_interaction(interaction, matched_plugin_module)

        %{
          interaction: interaction,
          parsed_application_command_name_list: parsed_application_command_name_list,
          parsed_options: parsed_options,
          processed_middleware_data: processed_middleware_data,
          ephemeral: ephemeral?,
          plugin_module: matched_plugin_module
        }
        |> InteractionProcessingWorker.new()
        |> Oban.insert()
    end

    :ok
  end
end
