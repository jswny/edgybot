defmodule Edgybot.Bot.Plugin.ChatPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Edgybot.External.Discord
  alias Edgybot.External.Kagi
  alias Edgybot.External.OpenRouter, as: OpenRouterAPI
  alias Edgybot.External.Qdrant
  alias Nostrum.Api
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Interaction
  alias Nostrum.Struct.User

  @context_chunk_size 100

  @impl true
  def get_plugin_definitions do
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
              description: "The model to use. See: https://openrouter.ai/models",
              type: 3,
              required: false
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
            },
            %{
              name: "debug",
              description: "Output extra debugging information",
              type: 5,
              required: false
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
          user: %User{username: caller_username},
          member: %Member{nick: caller_nick},
          guild_id: guild_id,
          channel_id: channel_id
        },
        _middleware_data
      ) do
    endpoint = "chat/completions"
    default_model = Application.get_env(:edgybot, OpenRouter)[:default_model]

    num_recent_context_messages = find_option_value(other_options, "context")

    model =
      find_option_value(other_options, "model") || default_model

    behavior = find_option_value(other_options, "behavior")
    temperature = find_option_value(other_options, "temperature")

    recent_context_messages =
      if num_recent_context_messages do
        guild_id
        |> get_recent_context_messages(channel_id, num_recent_context_messages)
        |> Enum.reverse()
        |> List.flatten()
      else
        []
      end

    system_messages = generate_system_messages(behavior)

    prompt_message = %{
      role: "user",
      name: Discord.sanitize_chat_message_name(caller_nick, caller_username),
      content: prompt
    }

    body =
      %{
        model: model,
        temperature: temperature
      }

    tools = %{
      tool_definition_search_group_messages().name => %{
        type: "function",
        function: tool_definition_search_group_messages()
      },
      tool_definition_search_internet().name => %{
        type: "function",
        function: tool_definition_search_internet()
      },
      tool_definition_list_group_users().name => %{
        type: "function",
        function: tool_definition_list_group_users()
      }
    }

    completion_metadata = %{guild_id: guild_id, prompt: prompt}

    case generate_completion_with_tools(
           endpoint,
           body,
           system_messages,
           recent_context_messages,
           prompt_message,
           tools,
           completion_metadata
         ) do
      {:ok, chat_response, metadata} ->
        debug = find_option_value(other_options, "debug")

        fields =
          generate_fields(
            prompt,
            num_recent_context_messages,
            model,
            behavior,
            temperature,
            Map.get(metadata, :supported_params),
            debug && Map.get(metadata, :tool_calls)
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

  defp generate_system_messages do
    today = Date.utc_today()
    today_formatted = Calendar.strftime(today, "%A %B %d, %Y")

    [
      %{role: "system", content: Config.openai_chat_system_prompt_base()},
      %{role: "system", content: Config.openai_chat_system_prompt_context()},
      %{role: "system", content: "Today's UTC date is #{today_formatted}"}
    ]
  end

  defp generate_system_messages(nil), do: generate_system_messages()

  defp generate_system_messages(behavior) do
    generate_system_messages() ++
      [
        %{role: "system", content: behavior}
      ]
  end

  defp generate_completion_with_tools(url, body, system_messages, conversation_messages, prompt_message, tools, metadata) do
    prompt_messages = if prompt_message, do: [prompt_message], else: []
    conversation_messages = Enum.concat(conversation_messages, prompt_messages)
    messages = Enum.concat([system_messages, conversation_messages])

    body = Map.put(body, :messages, messages)
    {body, metadata} = update_with_tools_support(body, metadata, tools)

    response = OpenRouterAPI.post_and_handle_errors(url, body)

    generate_completion_with_tools(
      response,
      url,
      body,
      system_messages,
      conversation_messages,
      prompt_message,
      tools,
      metadata
    )
  end

  defp generate_completion_with_tools(
         {:error, _error} = result,
         _url,
         _body,
         _system_messages,
         _conversation_messages,
         _prompt_message,
         _tools,
         _metadata
       ) do
    result
  end

  defp generate_completion_with_tools(
         {:ok, %{"error" => %{"code" => code, "message" => message}}},
         _url,
         _body,
         _system_messages,
         _conversation_messages,
         _prompt_message,
         _tools,
         _metadata
       ) do
    error_message = "Error code: #{code}, message: #{message}"
    {:error, error_message}
  end

  defp generate_completion_with_tools(
         {:ok, %{"choices" => [%{"message" => %{"tool_calls" => tool_calls} = message} | _other_choices]}},
         url,
         body,
         system_messages,
         conversation_messages,
         _prompt_message,
         tools,
         metadata
       ) do
    conversation_messages = Enum.concat([conversation_messages, [message]])

    case add_tool_calls_to_metadata(metadata, tool_calls) do
      {:ok, metadata} ->
        generate_completion_with_tools(
          {:ok, :tool_calls},
          url,
          body,
          system_messages,
          conversation_messages,
          nil,
          tools,
          tool_calls,
          metadata
        )

      {:error, error} ->
        {:error, error}
    end
  end

  defp generate_completion_with_tools(
         {:ok, %{"model" => model, "choices" => [%{"message" => %{"content" => content}} | _other_choices]}},
         _url,
         _body,
         _system_messages,
         _conversation_messages,
         _prompt_message,
         _tools,
         metadata
       ) do
    metadata = Map.put(metadata, :model, model)
    {:ok, content, metadata}
  end

  defp generate_completion_with_tools(
         {:ok, :tool_calls},
         url,
         body,
         system_messages,
         conversation_messages,
         prompt_message,
         tools,
         [],
         metadata
       ) do
    generate_completion_with_tools(
      url,
      body,
      system_messages,
      conversation_messages,
      prompt_message,
      tools,
      metadata
    )
  end

  defp generate_completion_with_tools(
         {:ok, :tool_calls} = response,
         url,
         body,
         system_messages,
         conversation_messages,
         prompt_message,
         tools,
         [
           %{"id" => tool_call_id, "function" => %{"name" => tool_call_name, "arguments" => tool_call_arguments}}
           | remaining_tool_calls
         ],
         metadata
       ) do
    tool_call_arguments = Jason.decode!(tool_call_arguments)
    tool_call_result = call_tool_with_cache(tool_call_name, tool_call_arguments, metadata)

    tool_call_content =
      case tool_call_result do
        {:ok, tool_call_content} -> tool_call_content
        {:error, error} -> "Error calling tool: #{inspect(error)}"
      end

    tool_call_message = %{
      role: "tool",
      tool_call_id: tool_call_id,
      content: tool_call_content
    }

    conversation_messages =
      conversation_messages ++ [tool_call_message]

    generate_completion_with_tools(
      response,
      url,
      body,
      system_messages,
      conversation_messages,
      prompt_message,
      tools,
      remaining_tool_calls,
      metadata
    )
  end

  defp update_with_tools_support(body, metadata, tools) do
    tool_definitions = Map.values(tools)
    supports_tools? = model_supports_parameters?(body.model, "tools")
    tools_param = :tools

    updated_body =
      if supports_tools? && length(tool_definitions) > 0 do
        Map.put(body, tools_param, tool_definitions)
      else
        body
      end

    default_params = if supports_tools?, do: [tools_param], else: []

    updated_metadata =
      Map.update(metadata, :supported_params, default_params, fn params ->
        if supports_tools? && !Enum.member?(params, tools_param) do
          [tools_param | params]
        else
          params
        end
      end)

    {updated_body, updated_metadata}
  end

  defp add_tool_calls_to_metadata(metadata, tool_calls) do
    result =
      Enum.reduce_while(tool_calls, metadata, fn %{
                                                   "function" => %{
                                                     "name" => tool_call_name,
                                                     "arguments" => tool_call_arguments
                                                   }
                                                 },
                                                 metadata_acc ->
        case Jason.decode(tool_call_arguments) do
          {:ok, tool_call_arguments_decoded} ->
            tool_call_metadata = %{name: tool_call_name, arguments: tool_call_arguments_decoded}

            updated_metadata =
              Map.update(metadata_acc, :tool_calls, [tool_call_metadata], fn existing_tool_call_metadatas ->
                [tool_call_metadata | existing_tool_call_metadatas]
              end)

            {:cont, updated_metadata}

          {:error, error} ->
            {:halt, {:error, error}}
        end
      end)

    case result do
      {:error, error} ->
        {:error, "Error deserializing tool calls: #{inspect(error)}"}

      updated_metadata ->
        {:ok, updated_metadata}
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
      %{
        role: "user",
        name: Discord.get_user_sanitized_chat_message_name(guild_id, user_id),
        content: content
      }
    end)
  end

  defp call_tool_with_cache(name, arguments, metadata) do
    cache_key = %{name: name, arguments: arguments}

    cache_result =
      Cachex.fetch(:model_tool_call_cache, cache_key, fn _key ->
        case call_tool(name, arguments, metadata) do
          {:ok, tool_call_result, expire} -> {:commit, tool_call_result, expire: expire}
          {:error, error} -> {:ignore, "Error calling tool: #{inspect(error)}"}
        end
      end)

    case cache_result do
      {:ignore, error} -> {:error, error}
      {_, tool_call_result} -> {:ok, tool_call_result}
    end
  end

  defp call_tool("list_group_users", _body, %{guild_id: guild_id}) do
    users =
      guild_id
      |> MemberCache.by_guild()
      |> Enum.map(fn member ->
        user_id = member.user_id
        %{id: user_id, name: Discord.get_user_sanitized_chat_message_name(guild_id, user_id)}
      end)

    data = %{"data" => users}

    case Jason.encode(data) do
      {:ok, ecoded_data} -> {:ok, ecoded_data, :timer.minutes(5)}
      {:error, error} -> {:error, "Error getting users: #{inspect(error)}"}
    end
  end

  defp call_tool("search_internet", %{"query" => _query} = body, _metadata) do
    case Kagi.post_and_handle_errors("/fastgpt", body) do
      {:ok, %{"data" => %{"output" => output}}} ->
        {:ok, output, :timer.hours(1)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp call_tool("search_group_messages", %{"query" => query}, %{guild_id: guild_id}) do
    universal_context_min_score = Config.chat_plugin_universal_context_min_score()
    universal_context_limit = Config.chat_plugin_universal_context_max_size()
    collection = Config.qdrant_collection_discord_messages()

    universal_context_messages_result =
      case Qdrant.embed_and_find_closest(
             collection,
             query,
             universal_context_limit,
             score_threshold: universal_context_min_score
           ) do
        {:ok, %{"result" => result_batch}} ->
          {:ok, enrich_universal_context_batch(result_batch, guild_id)}

        {:error, error} ->
          {:error, error}
      end

    case universal_context_messages_result do
      {:ok, universal_context_messages} ->
        formatted_content =
          universal_context_messages
          |> Enum.reduce(
            [
              "Here are some historical messages that may or may not be relevant to the current query: "
            ],
            fn %{name: name, content: content}, acc ->
              ["[#{name}] '#{content}', " | acc]
            end
          )
          |> Enum.reverse()
          |> IO.iodata_to_binary()

        {:ok, formatted_content, :timer.hours(1)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_recent_context_messages(guild_id, channel_id, num_messages)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages),
       do: get_recent_context_messages(guild_id, channel_id, num_messages, {}, [])

  defp get_recent_context_messages(guild_id, channel_id, 0, _locator, acc)
       when is_integer(guild_id) and is_integer(channel_id),
       do: acc |> Enum.reverse() |> List.flatten()

  defp get_recent_context_messages(guild_id, channel_id, num_messages, _locator, acc)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and num_messages < 0 do
    flattened = acc |> Enum.reverse() |> List.flatten()
    Enum.take(flattened, length(flattened) - -num_messages)
  end

  defp get_recent_context_messages(guild_id, channel_id, num_messages, locator, acc)
       when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and is_list(acc) do
    all_messages = Api.get_channel_messages!(channel_id, @context_chunk_size, locator)

    filtered_messages =
      all_messages
      |> Enum.filter(&message_valid?/1)
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

  defp message_valid?(message) do
    message.author.bot != true && message.content != nil && message.content != ""
  end

  defp generate_fields(prompt, num_context_messages, model, behavior, temperature, supported_params, tool_calls)
       when is_binary(prompt) and is_binary(model) and is_integer(num_context_messages)
       when is_binary(behavior) or is_nil(behavior)
       when is_float(temperature) or is_nil(temperature)
       when is_list(supported_params) or is_nil(supported_params)
       when is_list(tool_calls) or is_nil(tool_calls) do
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

    supported_params_value =
      case supported_params do
        nil -> nil
        [] -> Designer.code_inline("None")
        _ -> supported_params |> Enum.join(", ") |> Designer.code_inline()
      end

    supported_params_field = %{
      name: "Supported Params",
      value: supported_params_value,
      inline: true
    }

    tool_calls_field = get_tool_calls_field(tool_calls)

    [
      prompt_field,
      context_field,
      model_field,
      behavior_field,
      temperature_field,
      supported_params_field,
      tool_calls_field
    ]
  end

  defp get_tool_calls_field(tool_calls) do
    tool_calls_value =
      case tool_calls do
        nil -> nil
        [] -> nil
        _ -> tool_calls |> Jason.encode!(pretty: true) |> Designer.code_block()
      end

    %{
      name: "Tool Calls",
      value: tool_calls_value,
      inline: true
    }
  end

  defp tool_definition_search_group_messages do
    %{
      name: "search_group_messages",
      description:
        "Searches messages in the group related to a specific query. Searches using a vector database of embeddings and a similarity function. Messages in the database are embedded as their raw text.",
      strict: true,
      parameters: %{
        type: "object",
        required: ["query"],
        properties: %{
          query: %{
            type: "string",
            description: "Query to search for related messages. Will be embedded before search is performed."
          }
        },
        additionalProperties: false
      }
    }
  end

  defp tool_definition_list_group_users do
    %{
      name: "list_group_users",
      description: "Lists all of the users in the group along with their names and information.",
      strict: true,
      parameters: %{
        type: "object",
        required: [],
        properties: %{},
        additionalProperties: false
      }
    }
  end

  defp tool_definition_search_internet do
    %{
      name: "search_internet",
      description: "Searches the internet for information related to a specific query.",
      strict: true,
      parameters: %{
        type: "object",
        required: ["query"],
        properties: %{
          query: %{
            type: "string",
            description: "Query to search for."
          }
        },
        additionalProperties: false
      }
    }
  end

  defp model_supports_parameters?(model, parameters) do
    cache_result =
      Cachex.fetch(:openrouter_models_cache, parameters, fn _key ->
        {:ok, %{"data" => models}} = OpenRouterAPI.get("models", supported_parameters: parameters)
        {:commit, models}
      end)

    model_definitions =
      case cache_result do
        {:ok, models} -> models
        {:commit, models} -> models
      end

    Enum.any?(model_definitions, fn model_definition -> model_definition["id"] == model end)
  end
end
