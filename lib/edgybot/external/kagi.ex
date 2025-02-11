defmodule Edgybot.External.Kagi do
  @moduledoc false

  def post_and_handle_errors(endpoint, body) when is_binary(endpoint) and is_map(body) do
    req = create_client()

    response = Req.post(req, url: endpoint, json: body)

    case response do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}
    end
  end

  defp create_client do
    base_url = Application.get_env(:edgybot, Kagi)[:base_url]
    api_key = Application.get_env(:edgybot, Kagi)[:api_key]
    timeout = Application.get_env(:edgybot, Kagi)[:timeout]

    Req.new(base_url: base_url, receive_timeout: timeout, auth: "Bot #{api_key}")
  end
end
