defmodule Edgybot.External.Fal do
  alias Edgybot.Config

  def call_and_handle_errors(opts) do
    opts = Keyword.put_new(opts, :retry, :transient)

    case call(opts) do
      {:ok, %{body: %{"detail" => error}}} ->
        {:error, error}

      {:error, message} ->
        {:error, message}

      {:ok, response} ->
        {:ok, response}
    end
  end

  def add_status_retry(opts) do
    retry_count = Config.fal_status_retry_count()

    opts
    |> Keyword.put_new(:retry, &status_retry_fun/2)
    |> Keyword.put_new(:retry_log_level, :debug)
    |> Keyword.put_new(:max_retries, retry_count)
    |> Keyword.put_new(:retry_delay, 50)
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

    Req.new(base_url: base_url, receive_timeout: timeout)
    |> Req.Request.put_header("Authorization", "Key #{api_key}")
  end
end
