defmodule Edgybot.OpenAI do
  @moduledoc false

  alias Edgybot.Config

  def sanitize_chat_message_name(name, fallback_value)
      when is_nil(name) and is_binary(fallback_value) do
    cache_result =
      Cachex.fetch(:processed_string_cache, name, fn _key -> {:commit, fallback_value} end)

    case cache_result do
      {:ok, value} -> value
      {:commit, value} -> value
    end
  end

  def sanitize_chat_message_name(name, fallback_value)
      when is_binary(name) and is_binary(fallback_value) do
    regex = ~r/[a-zA-Z0-9_-]/

    cache_result =
      Cachex.fetch(:processed_string_cache, name, fn key ->
        sanitized =
          key
          |> String.graphemes()
          |> Enum.filter(fn grapheme -> String.match?(grapheme, regex) end)
          |> Enum.join()

        result = if sanitized == "", do: fallback_value, else: sanitized

        {:commit, result}
      end)

    case cache_result do
      {:ok, value} -> value
      {:commit, value} -> value
    end
  end

  def post_and_handle_errors(endpoint, body, user_id)
      when is_binary(endpoint) and is_map(body) and is_integer(user_id) do
    req = create_client()

    default_body = %{
      user: Integer.to_string(user_id)
    }

    body =
      default_body
      |> Map.merge(body)
      |> Enum.filter(fn {_, value} -> value != nil end)
      |> Enum.into(%{})

    response = Req.post(req, url: endpoint, json: body)

    case response do
      {:ok, response} ->
        json_response =
          response
          |> Map.fetch!(:body)

        case json_response do
          %{"error" => %{"message" => message}} ->
            {:error, message}

          data ->
            {:ok, data}
        end

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, "Request timed out."}
    end
  end

  defp create_client do
    base_url = Config.openai_base_url()
    api_key = Config.openai_api_key()
    timeout = Config.openai_timeout()
    auth = {:bearer, api_key}

    Req.new(base_url: base_url, auth: auth, receive_timeout: timeout)
  end
end
