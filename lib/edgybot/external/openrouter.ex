defmodule Edgybot.External.OpenRouter do
  @moduledoc false

  @completions_endpoint "chat/completions"
  @models_endpoint "models"

  def generate_completion(body) do
    body =
      body
      |> Enum.filter(fn {_, value} -> value != nil end)
      |> Map.new()

    opts = [method: :post, url: @completions_endpoint, json: body]
    call_and_handle_errors(opts)
  end

  def model_supports_parameters?(model, parameters) do
    cache_result =
      Cachex.fetch(:openrouter_models_cache, parameters, fn _key ->
        {:ok, %{"data" => models}} = get_models(supported_parameters: parameters)
        {:commit, models}
      end)

    model_definitions =
      case cache_result do
        {:ok, models} -> models
        {:commit, models} -> models
      end

    Enum.any?(model_definitions, fn model_definition -> model_definition["id"] == model end)
  end

  defp get_models(params) do
    opts = [method: :get, url: @models_endpoint, params: params]
    call_and_handle_errors(opts)
  end

  defp call_and_handle_errors(opts) do
    opts = Keyword.put_new(opts, :retry, :transient)

    case call(opts) do
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

  defp call(opts) do
    client = create_client()
    Req.request(client, opts)
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
