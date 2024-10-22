defmodule Edgybot.Workers.OpenAIModerationWorker do
  alias Edgybot.Clients.OpenAIClient
  alias Edgybot.Workers.OpenAIFileWorker

  use Oban.Worker,
    queue: :openai_moderate,
    tags: ["openai"]

  @chunk_size 16

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "type" => "fine-tune",
          "content_list" => content_list,
          "user_id" => user_id,
          "num_messages" => num_messages
        }
      })
      when is_list(content_list) do
    IO.inspect("Got moderation request")

    client = OpenAIClient.client()

    moderated_content =
      content_list
      |> Enum.chunk_every(@chunk_size)
      |> Enum.map(fn inputs_chunk ->
        encoded_inputs_chunk = Enum.map(inputs_chunk, &Jason.encode!(&1))

        {:ok, %Tesla.Env{body: %{"results" => results}}} =
          OpenAIClient.moderate(client, encoded_inputs_chunk)

        inputs_chunk
        |> Enum.zip(results)
        |> Enum.filter(fn {item, result} -> is_flagged?(item, result) end)
        |> Enum.map(fn {item, _} -> item end)
      end)
      |> List.flatten()

    IO.inspect("Content moderated, found #{Enum.count(moderated_content)} valid items")

    %{
      type: "fine-tune",
      purpose: "fine-tune",
      content_list: moderated_content,
      user_id: user_id,
      num_messages: num_messages
    }
    |> OpenAIFileWorker.new()
    |> Oban.insert()

    :ok
  end

  def is_flagged?(item, results_block) when is_map(results_block) do
    flagged = results_block["flagged"] == true
    categories = results_block["categories"]

    any_category_true =
      categories
      |> Map.keys()
      |> Enum.any?(fn key -> categories[key] == true end)

    # TODO: remove this and the item arg
    # if flagged || any_category_true do
    #   IO.puts("Found flagged content")
    #   IO.inspect(item)
    #   IO.inspect(categories)
    # end

    flagged || any_category_true
  end
end
