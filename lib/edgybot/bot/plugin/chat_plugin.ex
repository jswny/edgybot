defmodule Edgybot.Bot.Plugin.ChatPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.Designer
  alias Edgybot.{Config, OpenAI}

  alias Nostrum.Api
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.{Interaction, User}

  @context_chunk_size 100

  @impl true
  def get_plugin_definitions do
    model_choices = Config.openai_chat_models()
    max_context_size = Config.chat_plugin_max_context_size()

    [
      %{
        application_command: %{
          name: "chat",
          description: "Chat with an AI",
          type: 1,
          options: [
            %{
              name: "prompt",
              description: "The prompt for the AI to respond to",
              type: 3,
              required: true
            },
            %{
              name: "context",
              description: "Number of previous chat messages to include as context",
              type: 4,
              required: false,
              min_value: 1,
              max_value: max_context_size
            },
            %{
              name: "model",
              description: "The model to use. Default: #{Enum.at(model_choices, 0).name}",
              type: 3,
              required: false,
              choices: model_choices
            },
            %{
              name: "behavior",
              description: "Tell the AI how it should behave",
              type: 3,
              required: false
            },
            %{
              name: "presence-penalty",
              description: "Penalize or incentivize the AI to talk about new topics",
              type: 10,
              required: false,
              min_value: -2.0,
              max_value: 2.0
            },
            %{
              name: "frequency-penalty",
              description: "Penalize or incentivize the AI to repeat itself",
              type: 10,
              required: false,
              min_value: -2.0,
              max_value: 2.0
            },
            %{
              name: "temperature",
              description: "How deterministic the AI's response should be",
              type: 10,
              required: false,
              min_value: 0,
              max_value: 2.0
            },
            %{
              name: "top-p",
              description:
                "Another method of specifying how deterministic the AI's response should be",
              type: 10,
              required: false,
              min_value: 0,
              max_value: 1.0
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["chat"],
        1,
        [{"prompt", 3, prompt} | other_options],
        %Interaction{
          user: %User{id: caller_user_id, username: caller_username},
          member: %Member{nick: caller_nick},
          guild_id: guild_id,
          channel_id: channel_id
        },
        _middleware_data
      ) do
    url = "https://api.openai.com/v1/chat/completions"
    available_models = Config.openai_chat_models()

    num_context_messages = find_option_value(other_options, "context")

    model =
      find_option_value(other_options, "model") || Enum.at(available_models, 0).value

    behavior = find_option_value(other_options, "behavior")
    presence_penalty = find_option_value(other_options, "presence-penalty")
    frequency_penalty = find_option_value(other_options, "frequency-penalty")
    temperature = find_option_value(other_options, "temperature")
    top_p = find_option_value(other_options, "top-p")

    context_messages =
      if num_context_messages do
        guild_id
        |> get_context_messages(channel_id, num_context_messages)
        |> Enum.reverse()
        |> List.flatten()
      else
        []
      end

    messages =
      context_messages ++
        [
          %{
            role: "user",
            name: OpenAI.sanitize_chat_message_name(caller_nick, caller_username),
            content: prompt
          }
        ]

    enriched_behavior =
      if num_context_messages,
        do:
          "#{Config.openai_chat_system_prompt_base()}\n#{Config.openai_chat_system_prompt_context()}\n#{behavior}",
        else: "#{Config.openai_chat_system_prompt_base()}\n#{behavior}"

    messages =
      if behavior do
        [%{role: "system", content: enriched_behavior} | messages]
      else
        messages
      end

    body =
      %{
        model: model,
        messages: messages,
        presence_penalty: presence_penalty,
        frequency_penalty: frequency_penalty,
        temperature: temperature,
        top_p: top_p
      }

    case OpenAI.post_and_handle_errors(url, body, caller_user_id) do
      {:ok, response} ->
        chat_response =
          response
          |> Map.fetch!("choices")
          |> Enum.at(0)
          |> Map.fetch!("message")
          |> Map.fetch!("content")

        fields =
          generate_fields(
            prompt,
            num_context_messages,
            model,
            behavior,
            presence_penalty,
            frequency_penalty,
            temperature,
            top_p
          )

        options = [
          title: nil,
          description: chat_response,
          fields: fields
        ]

        {:success, options}

      {:error, message} ->
        {:warning, message}
    end
  end

  defp get_context_messages(guild_id, channel_id, num_messages)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages),
       do: get_context_messages(guild_id, channel_id, num_messages, {}, [])

  defp get_context_messages(guild_id, channel_id, 0, _locator, acc)
       when is_integer(guild_id) and is_integer(channel_id),
       do: Enum.reverse(acc) |> List.flatten()

  defp get_context_messages(guild_id, channel_id, num_messages, _locator, acc)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and
              num_messages < 0 do
    flattened = acc |> Enum.reverse() |> List.flatten()
    Enum.take(flattened, length(flattened) - -num_messages)
  end

  defp get_context_messages(guild_id, channel_id, num_messages, locator, acc)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and
              is_list(acc) do
    all_messages =
      channel_id
      |> Api.get_channel_messages!(@context_chunk_size, locator)

    filtered_messages =
      all_messages
      |> Enum.filter(fn message -> message.author.bot != true end)
      |> Enum.map(fn message ->
        member = Api.get_guild_member!(guild_id, message.author.id)

        sanitized_nick = OpenAI.sanitize_chat_message_name(member.nick, message.author.username)

        %{role: "user", name: sanitized_nick, content: message.content}
      end)

    earliest_message_id = List.last(all_messages).id
    num_filtered_messages = Enum.count(filtered_messages)

    get_context_messages(
      guild_id,
      channel_id,
      num_messages - num_filtered_messages,
      {:before, earliest_message_id},
      [
        filtered_messages | acc
      ]
    )
  end

  defp generate_fields(
         prompt,
         num_context_messages,
         model,
         behavior,
         presence_penalty,
         frequency_penalty,
         temperature,
         top_p
       )
       when is_binary(prompt) and is_binary(model) and is_integer(num_context_messages)
       when is_binary(behavior) or is_nil(behavior)
       when is_float(presence_penalty) or is_nil(presence_penalty)
       when is_float(frequency_penalty) or is_nil(frequency_penalty)
       when is_float(temperature) or is_nil(temperature)
       when is_float(top_p) or is_nil(top_p) do
    prompt_field = %{name: "Prompt", value: Designer.code_block(prompt)}

    context_field = %{
      name: "Context Size",
      value: num_context_messages && Designer.code_inline("#{num_context_messages}"),
      inline: true
    }

    model_field = %{name: "Model", value: Designer.code_inline(model), inline: true}

    behavior_field = %{
      name: "Behavior",
      value: behavior && Designer.code_inline("#{behavior}"),
      inline: true
    }

    presence_penalty_field = %{
      name: "Presence Penalty",
      value: presence_penalty && Designer.code_inline("#{presence_penalty}"),
      inline: true
    }

    frequency_penalty_field = %{
      name: "Frequency Penalty",
      value: frequency_penalty && Designer.code_inline("#{frequency_penalty}"),
      inline: true
    }

    temperature_field = %{
      name: "Temperature",
      value: temperature && Designer.code_inline("#{temperature}"),
      inline: true
    }

    top_p_field = %{
      name: "Top-P",
      value: top_p && Designer.code_inline("#{top_p}"),
      inline: true
    }

    [
      prompt_field,
      context_field,
      model_field,
      behavior_field,
      presence_penalty_field,
      frequency_penalty_field,
      temperature_field,
      top_p_field
    ]
  end
end
