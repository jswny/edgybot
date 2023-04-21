defmodule Edgybot.Bot.OpenAI do
  @moduledoc false

  alias Edgybot.Config

  def call_and_handle_errors(url, body, user_id)
      when is_binary(url) and is_map(body) and is_integer(user_id) do
    api_key = Config.openai_api_key()
    headers = [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{api_key}"}]

    default_body = %{
      user: Integer.to_string(user_id)
    }

    body =
      default_body
      |> Map.merge(body)
      |> Jason.encode!()

    timeout = Config.openai_timeout()

    response_tuple =
      :post
      |> Finch.build(url, headers, body)
      |> Finch.request(FinchPool, receive_timeout: timeout)

    case response_tuple do
      {:ok, response} ->
        json_response =
          response
          |> Map.fetch!(:body)
          |> Jason.decode!()

        case json_response do
          %{"error" => %{"message" => message}} ->
            {:error, message}

          data ->
            {:ok, data}
        end

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timed out."}
    end
  end
end
