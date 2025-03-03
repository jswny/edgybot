defmodule Edgybot.External.Qdrant do
  @moduledoc false
  alias Edgybot.External.OpenAI

  require Logger

  def call(method, endpoint) when is_atom(method) and is_binary(endpoint) do
    client = create_client()
    Req.request(client, method: method, url: endpoint)
  end

  def call(method, endpoint, body) when is_atom(method) and is_binary(endpoint) and is_map(body) do
    client = create_client()
    Req.request(client, method: method, url: endpoint, json: body)
  end

  def create_collections do
    discord_messages_collection = Application.get_env(:edgybot, Qdrant)[:collection_discord_messages]
    discord_messages_vector_size = Application.get_env(:edgybot, Qdrant)[:collection_discord_messages_vector_size]

    discord_messages_body = %{
      vectors: %{
        size: discord_messages_vector_size,
        distance: "Cosine"
      }
    }

    {:ok, %{status: 200, body: %{"result" => %{"exists" => exists?}}}} =
      call(:get, "collections/#{discord_messages_collection}/exists")

    if exists? do
      Logger.info("Qdrant collection #{discord_messages_collection} already exists")
    else
      {:ok, %{status: 200}} =
        call(:put, "collections/#{discord_messages_collection}", discord_messages_body)

      Logger.info("Qdrant collection #{discord_messages_collection} created")
    end
  end

  def embed_and_find_closest(collection, query, limit, options \\ [])
      when is_binary(collection) and is_binary(query) and is_integer(limit) do
    embedding_model = Application.get_env(:edgybot, OpenAI)[:embedding_model]

    embedding_body = %{input: query, model: embedding_model}

    case OpenAI.post_and_handle_errors("v1/embeddings", embedding_body) do
      {:ok, embedding_response} ->
        embedding =
          embedding_response
          |> Map.fetch!("data")
          |> Enum.at(0)
          |> Map.fetch!("embedding")

        score_threshold = Keyword.get(options, :score_threshold, 0.0)
        filter = Keyword.get(options, :filter, nil)

        search_body = %{
          vector: embedding,
          limit: limit,
          with_payload: true,
          score_threshold: score_threshold
        }

        search_body =
          if filter do
            Map.put(search_body, :filter, filter)
          else
            search_body
          end

        search_response =
          call(:post, "/collections/#{collection}/points/search", search_body)

        case search_response do
          {:ok, %{status: 200, body: response}} ->
            {:ok, response}

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp create_client do
    base_url = Application.get_env(:edgybot, Qdrant)[:api_url]
    api_key = Application.get_env(:edgybot, Qdrant)[:api_key]
    timeout = Application.get_env(:edgybot, Qdrant)[:timeout]
    auth = {:bearer, api_key}

    Req.new(base_url: base_url, auth: auth, receive_timeout: timeout)
  end
end
