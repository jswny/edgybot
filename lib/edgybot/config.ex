defmodule Edgybot.Config do
  @moduledoc false

  def runtime_env, do: fetch(:runtime_env)

  def application_command_prefix, do: fetch(:application_command_prefix)

  def memegen_url, do: fetch(:memegen_url)

  def archive_hosts_preserve_query do
    fetch(:archive_hosts_preserve_query)
    |> Enum.map(fn host -> [host, "www." <> host] end)
    |> List.flatten()
  end

  def openai_api_key, do: fetch(:openai_api_key)

  def openai_timeout, do: fetch(:openai_timeout)

  def openai_chat_models, do: fetch(:openai_chat_models)

  def openai_image_models, do: fetch(:openai_image_models)

  def openai_image_sizes do
    :openai_image_sizes
    |> fetch()
    |> Enum.map(fn size -> %{name: size, value: size} end)
  end

  defp fetch(key) when is_atom(key) do
    __MODULE__
    |> Application.get_application()
    |> Application.fetch_env!(key)
  end
end
