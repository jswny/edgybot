defmodule Edgybot.Workers.InteractionRespondingWorker do
  @moduledoc false
  use Oban.Worker,
    queue: :interaction_respond,
    max_attempts: 1,
    tags: ["discord", "interaction"]

  alias Edgybot.Bot.Designer
  alias Edgybot.Bot.Handler.ResponseHandler

  @impl Worker
  def perform(%Oban.Job{
        args: %{"interaction" => interaction, "ephemeral" => ephemeral?, "type" => "immediate", "exception" => exception}
      }) do
    response = {"error", %{"description" => Designer.code_block(exception)}}
    {:ok} = ResponseHandler.send_immediate_response(response, interaction, ephemeral?)

    :ok
  end

  @impl Worker
  def perform(%Oban.Job{
        args: %{
          "interaction" => interaction,
          "ephemeral" => ephemeral?,
          "type" => "immediate",
          "response" => %{"type" => response_type, "value" => response_value}
        }
      }) do
    {:ok} = ResponseHandler.send_immediate_response({response_type, response_value}, interaction, ephemeral?)

    :ok
  end

  @impl Worker
  def perform(%Oban.Job{
        args: %{"interaction" => interaction, "ephemeral" => ephemeral?, "type" => "followup", "exception" => exception}
      }) do
    response = {"error", %{"description" => Designer.code_block(exception)}}
    {:ok, _message} = ResponseHandler.send_followup_response(response, interaction, ephemeral?)

    :ok
  end

  @impl Worker
  def perform(%Oban.Job{
        args: %{
          "interaction" => interaction,
          "ephemeral" => ephemeral?,
          "type" => "followup",
          "response" => %{"type" => response_type, "value" => response_value}
        }
      }) do
    {:ok, _message} = ResponseHandler.send_followup_response({response_type, response_value}, interaction, ephemeral?)

    :ok
  end

  @impl Worker
  def backoff(%Job{attempt: attempt}) do
    attempt
  end
end
