defmodule Edgybot.Bot.Plugin.AIPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.AI
  alias Edgybot.Bot.Cache.MessageCacheSlim
  alias Edgybot.Bot.Designer
  alias Edgybot.External.Discord
  alias Edgybot.External.OpenRouter, as: OpenRouterAPI
  alias Nostrum.Api.Message, as: MessageApi
  alias Nostrum.Cache.Me

  @output_schema_response_decision %{
    name: "response_decision",
    schema: %{
      type: "object",
      properties: %{
        should_respond: %{
          type: "boolean",
          description: "Indicates whether a response should be provided based on the system prompt."
        },
        response: %{
          type: "string",
          description: "The response provided if should_respond is true."
        }
      },
      required: ["should_respond", "response"],
      additionalProperties: false
    },
    strict: true
  }
  @typing_refresh_time 7_000

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "ai",
          description: "Setup automatic interactive AI",
          type: 1,
          options: [
            %{
              name: "enable",
              description: "Enable AI in this channel",
              type: 1
            },
            %{
              name: "disable",
              description: "Disable AI in this channel",
              type: 1
            },
            %{
              name: "model",
              description: "Set the AI model for this channel",
              type: 1,
              options: [
                %{
                  name: "model",
                  description: "The model to use",
                  type: 3,
                  required: true
                }
              ]
            },
            %{
              name: "prompt",
              description: "Set the AI prompt for this channel",
              type: 1,
              options: [
                %{
                  name: "prompt",
                  description: "The prompt to use",
                  type: 3,
                  required: true
                }
              ]
            },
            %{
              name: "status",
              description: "Get the current AI status for this channel",
              type: 1
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(["ai", "enable"], 1, %{}, %{guild_id: guild_id, channel_id: channel_id}, _) do
    {:ok, _changeset} = AI.set_channel_settings(%{guild_id: guild_id, channel_id: channel_id, enabled: true})
    {:success, "Enabled AI for this channel"}
  end

  @impl true
  def handle_interaction(["ai", "disable"], 1, %{}, %{guild_id: guild_id, channel_id: channel_id}, _) do
    {:ok, _changeset} = AI.set_channel_settings(%{guild_id: guild_id, channel_id: channel_id, enabled: false})
    {:success, "Enabled AI for this channel"}
  end

  @impl true
  def handle_interaction(["ai", "model"], 1, %{"model" => model}, %{guild_id: guild_id, channel_id: channel_id}, _) do
    models_result = OpenRouterAPI.get_models()

    case models_result do
      {:ok, %{"data" => api_models}} ->
        matched_model = Enum.any?(api_models, fn api_model -> api_model["id"] == model end)

        if matched_model do
          {:ok, _changeset} = AI.set_channel_settings(%{guild_id: guild_id, channel_id: channel_id, model: model})
          {:success, "Set the model for this channel to: #{Designer.code_block(model)}"}
        else
          {:warning, "Model #{Designer.code_inline(model)} was not found!"}
        end

      _ ->
        {:error, "Error verifying model"}
    end
  end

  @impl true
  def handle_interaction(["ai", "prompt"], 1, %{"prompt" => prompt}, %{guild_id: guild_id, channel_id: channel_id}, _) do
    {:ok, _changeset} = AI.set_channel_settings(%{guild_id: guild_id, channel_id: channel_id, prompt: prompt})
    {:success, "Set the prompt for this channel to: #{Designer.code_block(prompt)}"}
  end

  @impl true
  def handle_interaction(["ai", "status"], 1, %{}, %{channel_id: channel_id}, _) do
    channel_settings = AI.get_channel_settings(channel_id)

    enabled_field = %{
      name: "Enabled",
      value: Designer.code_inline("#{channel_settings.enabled}"),
      inline: true
    }

    channel_messages_count =
      channel_id
      |> MessageCacheSlim.get_by_channel()
      |> Enum.count()

    conversation_size_field = %{
      name: "Conversation Size",
      value: Designer.code_inline("#{channel_messages_count}"),
      inline: true
    }

    prompt_field = %{
      name: "Prompt",
      value: Designer.code_block(channel_settings.prompt),
      inline: false
    }

    fields = [enabled_field, conversation_size_field, prompt_field]
    response_options = %{title: "AI Status", fields: fields}

    {:success, response_options}
  end

  def handle_message(%{channel_id: channel_id, author: %{id: author_id}} = message) do
    if should_respond_in_channel?(channel_id, author_id) do
      maybe_send_with_typing(channel_id, fn ->
        %{"should_respond" => should_respond, "response" => response} = determine_response(message)

        if should_respond && response do
          {:ok, response}
        else
          :noop
        end
      end)
    end
  end

  def should_respond_in_channel?(channel_id, author_id) do
    bot_user_id = Me.get().id

    channel_settings = AI.get_channel_settings(channel_id) || %{}

    author_id != bot_user_id && Map.get(channel_settings, :enabled, false)
  end

  def determine_response(%{guild_id: guild_id, channel_id: channel_id} = _message) do
    bot_user_id = Me.get().id

    channel_settings = AI.get_channel_settings(channel_id) || %{}

    channel_messages = MessageCacheSlim.get_by_channel(channel_id)

    messages = AI.generate_chat_messages_with_roles(channel_messages, guild_id, bot_user_id)

    model = channel_settings.model || Application.get_env(:edgybot, AIConfig)[:default_model]

    base_prompt = Application.get_env(:edgybot, AIConfig)[:base_prompt]
    self_identification_prompt = generate_self_identification_prompt(guild_id, bot_user_id)
    channel_prompt = Map.get(channel_settings, :prompt, "")

    full_prompt =
      """
      #{base_prompt}
      #{self_identification_prompt}
      #{channel_prompt}
      """

    messages = [%{role: "system", content: full_prompt} | messages]

    body = %{
      model: model,
      response_format: %{
        type: "json_schema",
        json_schema: @output_schema_response_decision
      },
      messages: messages
    }

    endpoint = OpenRouterAPI.completions_endpoint()

    {:ok, %{"choices" => [%{"message" => %{"content" => response_decision_json}}]}} =
      OpenRouterAPI.post_and_handle_errors(endpoint, body)

    :json.decode(response_decision_json)
  end

  defp generate_self_identification_prompt(guild_id, bot_user_id) do
    bot_name = Discord.get_user_sanitized_chat_message_name(guild_id, bot_user_id)

    """
    Your name is #{bot_name}.
    Someone might refer to you by name, or with a mention which looks exactly like this: <@#{bot_user_id}>
    """
  end

  defp maybe_send_with_typing(channel_id, fun) do
    typing_task = Task.async(fn -> keep_typing(channel_id) end)

    response = fun.()

    Task.shutdown(typing_task, :brutal_kill)

    case response do
      {:ok, response} ->
        MessageApi.create(channel_id, response)

      _ ->
        :ok
    end
  end

  defp keep_typing(id) do
    Nostrum.Api.Channel.start_typing(id)
    Process.sleep(@typing_refresh_time)
    keep_typing(id)
  end
end
