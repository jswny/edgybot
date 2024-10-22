defmodule Edgybot.Workers.OpenAIFineTuneWorker do
  use Oban.Worker,
    queue: :openai_fine_tune,
    tags: ["openai"]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "type" => "fine-tune",
          "file_id" => file_id,
          "suffix" => suffix
        }
      }) do
    IO.inspect("Got fine tune request for file: #{file_id}")

    client = Edgybot.Clients.OpenAIClient.client()

    # TODO: get model from config
    {:ok, response} =
      Edgybot.Clients.OpenAIClient.create_fine_tune_job(
        client,
        file_id,
        "gpt-4o-mini-2024-07-18",
        "#{suffix}"
      )

    :ok
  end
end
