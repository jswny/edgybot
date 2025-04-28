defmodule Edgybot.Bot.Plugin.IndexPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Edgybot.External.Qdrant
  alias Edgybot.Workers.DiscordChannelBatchingWorker
  alias Nostrum.Struct.Interaction

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "index",
          description: "Index Discord data",
          type: 1,
          options: [
            %{
              name: "channel",
              description: "Index the current channel",
              type: 1
            },
            %{
              name: "channel-rm",
              description: "Delete the current channel's index",
              type: 1
            },
            %{
              name: "search",
              description: "Search the index for similar data",
              type: 1,
              options: [
                %{
                  name: "query",
                  description: "The query to search on the index",
                  type: 3,
                  required: true
                },
                %{
                  name: "limit",
                  description: "Number of results to return",
                  type: 4,
                  required: false,
                  min_value: 1,
                  max_value: 100
                },
                %{
                  name: "score-threshold",
                  description: "Minimum score for a result to be returned",
                  type: 10,
                  required: false,
                  min_value: 0,
                  max_value: 1
                }
              ]
            },
            %{
              name: "status",
              description: "Check the status of the index",
              type: 1
            }
          ]
        },
        metadata: %{
          name: "index",
          data: %{
            ephemeral: true
          }
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["index", "channel"],
        1,
        _options,
        %Interaction{guild_id: guild_id, channel_id: channel_id, channel: %{last_message_id: last_message_id}},
        _middleware_data
      ) do
    batch_size = Config.discord_channel_message_batch_size()

    %{
      guild_id: guild_id,
      channel_id: channel_id,
      batch_size: batch_size,
      latest_message_id: last_message_id
    }
    |> DiscordChannelBatchingWorker.new()
    |> Oban.insert()

    {:success, "Started indexing the current channel"}
  end

  @impl true
  def handle_interaction(
        ["index", "channel-rm"],
        1,
        _options,
        %{guild_id: guild_id, channel_id: channel_id},
        _middleware_data
      ) do
    points_collection = Config.qdrant_collection_discord_messages()

    body = %{
      filter: %{
        must: [
          %{key: :guild_id, match: %{value: guild_id}},
          %{key: :channel_id, match: %{value: channel_id}}
        ]
      }
    }

    {:ok, _response} =
      Qdrant.call(:post, "/collections/#{points_collection}/points/delete", body)

    {:success, "Started deleting the current channel's index"}
  end

  @impl true
  def handle_interaction(["index", "search"], 1, %{"query" => query} = options, %{guild_id: guild_id}, _middleware_data) do
    limit = Map.get(options, "limit", 10)
    score_threshold = Map.get(options, "limit", 0.0)
    points_collection = Config.qdrant_collection_discord_messages()

    case Qdrant.embed_and_find_closest(points_collection, query, limit,
           score_threshold: score_threshold,
           filter: %{must: [%{key: :guild_id, match: %{value: guild_id}}]}
         ) do
      {:ok, response} ->
        format_search_response(response, query)

      {:error, error} ->
        error_message = Exception.message(error)
        {:warning, "Failed to search the index. Error: #{error_message}"}
    end
  end

  @impl true
  def handle_interaction(["index", "status"], 1, _options, _interaction, _middleware_data) do
    points_collection = Config.qdrant_collection_discord_messages()

    {:ok, %{body: %{"result" => response_body}}} =
      Qdrant.call(:get, "/collections/#{points_collection}")

    formatted_response = """
    - Status: #{response_body["status"]}
    - Indexed vectors: #{response_body["indexed_vectors_count"]}
    - Points: #{response_body["points_count"]}
    - Segments: #{response_body["segments_count"]}
    """

    options = [
      title: "Index Status",
      description: formatted_response,
      fields: nil
    ]

    {:success, options}
  end

  defp format_search_response(response, query) when is_map(response) do
    formatted_results = format_search_results(response)
    description = "**Query** #{Designer.code_block(query)}" <> "\n" <> formatted_results

    time_formatted =
      response
      |> Map.fetch!("time")
      |> Float.to_string()
      |> Designer.code_inline()

    time_field = %{name: "Response Time", value: time_formatted}

    options = [
      title: "Search Results",
      fields: [time_field],
      description: description
    ]

    {:success, options}
  end

  defp format_search_results(%{"result" => []}), do: "No results found!"

  defp format_search_results(%{"result" => result}) when is_list(result) do
    Enum.map_join(result, "\n", fn %{
                                     "id" => id,
                                     "score" => score,
                                     "payload" => %{
                                       "user_id" => user_id,
                                       "channel_id" => channel_id,
                                       "content" => content,
                                       "timestamp" => timestamp
                                     }
                                   } ->
      id_value = id |> inspect() |> Designer.code_inline()
      score_value = score |> inspect() |> Designer.code_inline()
      user_id_value = user_id |> inspect() |> Designer.code_inline()
      channel_id_value = channel_id |> inspect() |> Designer.code_inline()

      timestamp_value =
        timestamp
        |> DateTime.from_unix!(:millisecond)
        |> DateTime.to_string()
        |> Designer.code_inline()

      content_value = Designer.code_block(content)

      "- Timestamp: #{timestamp_value}, ID: #{id_value}, score: #{score_value}, user: #{user_id_value}, channel: #{channel_id_value}\n#{content_value}"
    end)
  end
end
