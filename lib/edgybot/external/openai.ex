defmodule Edgybot.External.OpenAI do
  @moduledoc false

  alias Edgybot.Config

  def post_and_handle_errors(endpoint, body, user_id \\ nil)
      when is_binary(endpoint) and is_map(body) and (is_integer(user_id) or is_nil(user_id)) do
    req = create_client()

    default_body = if user_id != nil, do: %{user: Integer.to_string(user_id)}, else: %{}

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
