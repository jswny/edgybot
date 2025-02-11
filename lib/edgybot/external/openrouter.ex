defmodule Edgybot.External.OpenRouter do
  @moduledoc false

  def get(endpoint, params) do
    req = create_client()

    response = Req.get(req, url: endpoint, params: params)

    case response do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "Request failed with status #{status}"}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}
    end
  end

  def post_and_handle_errors(endpoint, body) when is_binary(endpoint) and is_map(body) do
    req = create_client()

    body =
      body
      |> Enum.filter(fn {_, value} -> value != nil end)
      |> Map.new()

    response = Req.post(req, url: endpoint, json: body)

    case response do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{body: %{"error" => %{"message" => message}}}} ->
        {:error, message}

      {:ok, %{status: status}} ->
        {:error, "Request failed with status #{status}"}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}
    end
  end

  defp create_client do
    base_url = Application.get_env(:edgybot, OpenRouter)[:base_url]
    api_key = Application.get_env(:edgybot, OpenRouter)[:api_key]
    timeout = Application.get_env(:edgybot, OpenRouter)[:timeout]

    auth = {:bearer, api_key}

    headers = %{"X-Title": "Edgybot", "HTTP-Referer": "https://edgybot.io"}

    Req.new(base_url: base_url, auth: auth, headers: headers, receive_timeout: timeout)
  end
end
