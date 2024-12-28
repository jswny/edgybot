defmodule Edgybot.Bot.Plugin.ChatPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Edgybot.External.{Discord, OpenAI, Qdrant}

  alias Nostrum.Api
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.{Interaction, User}

  @context_chunk_size 100

  @impl true
  def get_plugin_definitions do
    model_choices = Config.openai_chat_models()
    max_context_size = Config.chat_plugin_recent_context_max_size()

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
              name: "temperature",
              description: "How deterministic the AI's response should be",
              type: 10,
              required: false,
              min_value: 0,
              max_value: 2.0
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
    temperature = find_option_value(other_options, "temperature")

    universal_context_min_score = Config.chat_plugin_universal_context_min_score()
    universal_context_limit = Config.chat_plugin_universal_context_max_size()
    collection = Config.qdrant_collection_discord_messages()

    universal_context_messages =
      case Qdrant.embed_and_find_closest(
             collection,
             prompt,
             universal_context_limit,
             universal_context_min_score
           ) do
        {:ok, %{"result" => result_batch}} ->
          enrich_universal_context_batch(result_batch, guild_id)

        {:error, _} ->
          []
      end

    recent_context_messages =
      if num_context_messages do
        guild_id
        |> get_recent_context_messages(channel_id, num_context_messages)
        |> Enum.reverse()
        |> List.flatten()
      else
        []
      end

    context_messages =
      List.flatten([universal_context_messages | recent_context_messages])

    messages =
      context_messages ++
        [
          %{
            role: "user",
            name: Discord.sanitize_chat_message_name(caller_nick, caller_username),
            content: prompt
          }
        ]

    enriched_behavior =
      if length(context_messages) > 0,
        do:
          "#{Config.openai_chat_system_prompt_base()}\n#{Config.openai_chat_system_prompt_context()}\n#{behavior}",
        else: "#{Config.openai_chat_system_prompt_base()}\n#{behavior}"

    messages = [%{role: "system", content: enriched_behavior} | messages]

    body =
      %{
        model: model,
        messages: messages,
        temperature: temperature
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
            temperature
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

  defp enrich_universal_context_batch([], _guild_id), do: []

  defp enrich_universal_context_batch(batch, guild_id) do
    Enum.map(batch, fn %{
                         "payload" => %{
                           "user_id" => user_id,
                           "content" => content
                         }
                       } ->
      {%{nick: nick}, %{username: username}} = MemberCache.get_with_user(guild_id, user_id)

      %{
        role: "user",
        name: Discord.sanitize_chat_message_name(nick, username),
        content: content
      }
    end)
  end

  defp get_recent_context_messages(guild_id, channel_id, num_messages)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages),
       do: get_recent_context_messages(guild_id, channel_id, num_messages, {}, [])

  defp get_recent_context_messages(guild_id, channel_id, 0, _locator, acc)
       when is_integer(guild_id) and is_integer(channel_id),
       do: Enum.reverse(acc) |> List.flatten()

  defp get_recent_context_messages(guild_id, channel_id, num_messages, _locator, acc)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and
              num_messages < 0 do
    flattened = acc |> Enum.reverse() |> List.flatten()
    Enum.take(flattened, length(flattened) - -num_messages)
  end

  defp get_recent_context_messages(guild_id, channel_id, num_messages, locator, acc)
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

        sanitized_nick = Discord.sanitize_chat_message_name(member.nick, message.author.username)

        %{role: "user", name: sanitized_nick, content: message.content}
      end)

    earliest_message_id = List.last(all_messages).id
    num_filtered_messages = Enum.count(filtered_messages)

    get_recent_context_messages(
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
         temperature
       )
       when is_binary(prompt) and is_binary(model) and is_integer(num_context_messages)
       when is_binary(behavior) or is_nil(behavior)
       when is_float(temperature) or is_nil(temperature) do
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

    temperature_field = %{
      name: "Temperature",
      value: temperature && Designer.code_inline("#{temperature}"),
      inline: true
    }

    [
      prompt_field,
      context_field,
      model_field,
      behavior_field,
      temperature_field
    ]
  end
end
