defmodule Edgybot.Config do
  @moduledoc false

  def runtime_env, do: fetch(:runtime_env)

  def application_command_prefix, do: fetch(:application_command_prefix)

  def chat_plugin_recent_context_max_size, do: fetch(:chat_plugin_recent_context_max_size)

  def chat_plugin_universal_context_max_size, do: fetch(:chat_plugin_universal_context_max_size)

  def chat_plugin_universal_context_min_score, do: fetch(:chat_plugin_universal_context_min_score)

  def memegen_url, do: fetch(:memegen_url)

  def archive_hosts_preserve_query do
    :archive_hosts_preserve_query
    |> fetch()
    |> Enum.map(fn host -> [host, "www." <> host] end)
    |> List.flatten()
  end

  def openai_base_url, do: fetch(:openai_base_url)

  def openai_api_key, do: fetch(:openai_api_key)

  def openai_timeout, do: fetch(:openai_timeout)

  def openai_chat_models, do: fetch(:openai_chat_models)

  def openai_embedding_model, do: fetch(:openai_embedding_model)

  def openai_chat_system_prompt_context, do: fetch(:openai_chat_system_prompt_context)

  def openai_chat_system_prompt_base, do: fetch(:openai_chat_system_prompt_base)

  def discord_channel_message_batch_size, do: fetch(:discord_channel_message_batch_size)

  def discord_channel_message_batch_size_index, do: fetch(:discord_channel_message_batch_size_index)

  def qdrant_api_url, do: fetch(:qdrant_api_url)

  def qdrant_api_key, do: fetch(:qdrant_api_key)

  def qdrant_timeout, do: fetch(:qdrant_timeout)

  def qdrant_collection_discord_messages, do: fetch(:qdrant_collection_discord_messages)

  def qdrant_collection_discord_messages_vector_size, do: fetch(:qdrant_collection_discord_messages_vector_size)

  def fal_api_url, do: fetch(:fal_api_url)

  def fal_api_key, do: fetch(:fal_api_key)

  def fal_timeout, do: fetch(:fal_timeout)

  def fal_status_retry_count, do: fetch(:fal_status_retry_count)

  def fal_image_models_generate do
    :fal_image_models_generate
    |> fetch()
    |> Jason.decode!()
    |> Map.fetch!("models")
  end

  def fal_image_models_edit do
    :fal_image_models_edit
    |> fetch()
    |> Jason.decode!()
    |> Map.fetch!("models")
  end

  def fal_image_models_safety_checker_disable, do: fetch(:fal_image_models_safety_checker_disable)

  defp fetch(key) when is_atom(key) do
    __MODULE__
    |> Application.get_application()
    |> Application.fetch_env!(key)
  end
end
