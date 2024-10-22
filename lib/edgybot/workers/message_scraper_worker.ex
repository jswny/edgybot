defmodule Edgybot.Workers.MessageScrapeWorker do
  alias Edgybot.Bot.Discord
  alias Edgybot.Workers.OpenAIModerationWorker

  use Oban.Worker,
    queue: :discord_scrape_messages,
    tags: ["discord"]

  @message_type_reply 19

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "type" => "fine-tune",
            "user_id" => user_id,
            "guild_id" => guild_id,
            "channel_id" => channel_id,
            "num_messages" => num_messages
          } = args
      }) do
    IO.inspect("Got scrape request for user_id: #{user_id}")

    batch_size = Map.get(args, "batch_size", 100)

    messages =
      Discord.get_messages(
        guild_id,
        channel_id,
        num_messages,
        batch_size,
        [@message_type_reply],
        [
          user_id
        ]
      )
      |> Enum.map(fn message ->
        %{
          messages: [
            %{role: "user", content: message.parent_message},
            %{role: "assistant", content: message.content}
          ]
        }
      end)

    IO.inspect("Finished scraping messages for user_id: #{user_id}")

    File.write("training_data.jsonl", Enum.join(messages |> Enum.map(&Jason.encode!(&1)), "\n"))

    # messages =
    #   File.read!("training_data.jsonl") |> String.split("\n") |> Enum.map(&Jason.decode!(&1))

    # IO.inspect(Enum.at(messages, 0))

    %{type: "fine-tune", content_list: messages, user_id: user_id, num_messages: num_messages}
    |> OpenAIModerationWorker.new()
    |> Oban.insert()

    :ok
  end
end
