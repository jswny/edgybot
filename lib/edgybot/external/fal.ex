defmodule Edgybot.External.Fal do
  @moduledoc false
  alias Edgybot.Config

  def create_and_wait_for_image(model, body) do
    create_opts = [method: :post, url: model, json: body]

    case call_and_handle_errors(create_opts) do
      {:ok, %{status: 200, body: %{"status_url" => status_url}}} ->
        status_opts = add_status_retry(base_url: nil, method: :get, url: status_url)

        case call_and_handle_errors(status_opts) do
          {:ok, %{status: 200, body: %{"response_url" => response_url}}} ->
            get_image(response_url)

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_image(response_url) do
    get_opts = [method: :get, base_url: nil, url: response_url]

    case call_and_handle_errors(get_opts) do
      {:ok,
       %{
         status: 200,
         body: %{"images" => [_image | _]} = body
       }} ->
        {:ok, body}

      {:error, error} ->
        {:error, error}
    end
  end

  defp call_and_handle_errors(opts) do
    opts = Keyword.put_new(opts, :retry, :transient)

    case call(opts) do
      {:ok, %{body: %{"detail" => error}}} ->
        {:error, inspect(error)}

      {:error, message} ->
        {:error, message}

      {:ok, response} ->
        {:ok, response}
    end
  end

  defp add_status_retry(opts) do
    retry_count = Config.fal_status_retry_count()

    opts
    |> Keyword.put_new(:retry, &status_retry_fun/2)
    |> Keyword.put_new(:retry_log_level, :debug)
    |> Keyword.put_new(:max_retries, retry_count)
    |> Keyword.put_new(:retry_delay, 250)
  end

  defp status_retry_fun(_request, response) do
    case response do
      %Req.Response{status: 200, body: body} ->
        decode_response = Jason.decode(body)

        case decode_response do
          {:ok, %{"status" => "COMPLETED"}} ->
            false

          _ ->
            true
        end

      _ ->
        true
    end
  end

  defp call(opts) do
    client = create_client()
    Req.request(client, opts)
  end

  defp create_client do
    base_url = Config.fal_api_url()
    api_key = Config.fal_api_key()
    timeout = Config.fal_timeout()

    [base_url: base_url, receive_timeout: timeout]
    |> Req.new()
    |> Req.Request.put_header("Authorization", "Key #{api_key}")
  end
end
