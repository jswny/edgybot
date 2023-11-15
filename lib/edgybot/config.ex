defmodule Edgybot.Config do
  @moduledoc false

  def runtime_env, do: fetch(:runtime_env)

  def memegen_url, do: fetch(:memegen_url)

  def openai_api_key, do: fetch(:openai_api_key)

  def openai_chat_models, do: fetch(:openai_chat_models)

  defp fetch(key) when is_atom(key) do
    __MODULE__
    |> Application.get_application()
    |> Application.fetch_env!(key)
  end
end
