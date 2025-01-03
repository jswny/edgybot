defmodule Edgybot.Config do
  @moduledoc false

  def runtime_env, do: fetch(:runtime_env)

  def application_command_prefix, do: fetch(:application_command_prefix)

  def chat_plugin_max_context_size, do: fetch(:chat_plugin_max_context_size)

  def memegen_url, do: fetch(:memegen_url)

  def archive_hosts_preserve_query do
    fetch(:archive_hosts_preserve_query)
    |> Enum.map(fn host -> [host, "www." <> host] end)
    |> List.flatten()
  end

  def openai_base_url, do: fetch(:openai_base_url)

  def openai_api_key, do: fetch(:openai_api_key)

  def openai_timeout, do: fetch(:openai_timeout)

  def openai_chat_models, do: fetch(:openai_chat_models)

  def openai_image_models, do: fetch(:openai_image_models)

  def openai_embedding_model, do: fetch(:openai_embedding_model)

  def openai_image_sizes do
    :openai_image_sizes
    |> fetch()
    |> Enum.map(fn size -> %{name: size, value: size} end)
  end

  def openai_chat_system_prompt_context, do: fetch(:openai_chat_system_prompt_context)

  def openai_chat_system_prompt_base, do: fetch(:openai_chat_system_prompt_base)

  def discord_channel_message_batch_size, do: fetch(:discord_channel_message_batch_size)

  def discord_channel_message_batch_size_index,
    do: fetch(:discord_channel_message_batch_size_index)

  def qdrant_api_url, do: fetch(:qdrant_api_url)

  def qdrant_api_key, do: fetch(:qdrant_api_key)

  def qdrant_timeout, do: fetch(:qdrant_timeout)

  def qdrant_collection_discord_messages, do: fetch(:qdrant_collection_discord_messages)

  def qdrant_collection_discord_messages_vector_size,
    do: fetch(:qdrant_collection_discord_messages_vector_size)

  defp fetch(key) when is_atom(key) do
    __MODULE__
    |> Application.get_application()
    |> Application.fetch_env!(key)
  end
end
