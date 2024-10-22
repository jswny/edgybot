defmodule Edgybot.Clients.OpenAIClient do
  alias Tesla.Multipart
  alias Edgybot.Config

  def client() do
    api_key = Config.openai_api_key()

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.openai.com"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{api_key}"}]}
    ]

    timeout = Config.openai_timeout()
    adapter = {Tesla.Adapter.Finch, [name: FinchPool, recv_timeout: timeout]}

    Tesla.client(middleware, adapter)
  end

  def upload_file(client, purpose, file_name, content)
      when is_struct(client) and is_binary(purpose) and is_binary(content) and
             is_binary(file_name) do
    multipart =
      Multipart.new()
      |> Multipart.add_field("purpose", purpose)
      |> Multipart.add_file_content(content, file_name)

    Tesla.post(client, "/v1/files", multipart)
  end

  def moderate(client, content_list)
      when is_struct(client) and is_list(content_list) do
    body = %{
      input: content_list
    }

    Tesla.post(client, "/v1/moderations", body)
  end

  def create_fine_tune_job(client, file_id, model, suffix)
      when is_struct(client) and is_binary(file_id) and is_binary(model) and
             is_binary(suffix) do
    body = %{
      model: model,
      training_file: file_id,
      suffix: suffix
    }

    Tesla.post(client, "/v1/fine_tuning/jobs", body)
  end
end
