defmodule Edgybot.Workers.OpenAIFileWorker do
  alias Edgybot.Clients.OpenAIClient
  alias Edgybot.Workers.OpenAIFineTuneWorker

  use Oban.Worker,
    queue: :openai_files,
    tags: ["openai"]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "type" => "fine-tune",
          "purpose" => purpose,
          "content_list" => content_list,
          "user_id" => user_id,
          "num_messages" => num_messages
        }
      })
      when is_binary(purpose) and is_list(content_list) and is_integer(user_id) and
             is_integer(num_messages) do
    IO.inspect("Got upload file request")

    upload_content =
      content_list
      |> Enum.map(&Jason.encode!(&1))
      |> Enum.join("\n")

    current_time = :os.system_time(:second)

    file_name =
      "fine-tune-data-discord-user-#{user_id}-#{num_messages}-#{current_time}.jsonl"

    client = OpenAIClient.client()

    {:ok, %Tesla.Env{body: %{"id" => file_id}}} =
      OpenAIClient.upload_file(client, purpose, file_name, upload_content)

    IO.inspect("File uploaded")

    %{type: "fine-tune", file_id: file_id, suffix: user_id}
    |> OpenAIFineTuneWorker.new()
    |> Oban.insert()

    :ok
  end
end
