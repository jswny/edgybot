defmodule Edgybot.Bot.Plugin.ChatPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.Designer
  alias Edgybot.Config

  alias Nostrum.Struct.{Interaction, User}

  @model_choices [
    %{name: "GPT-3.5", value: "gpt-3.5-turbo"},
    %{name: "GPT-4", value: "gpt-4"}
  ]

  @impl true
  def get_plugin_definitions do
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
              name: "behavior",
              description: "Tell the AI how it should behave",
              type: 3,
              required: false
            },
            %{
              name: "model",
              description: "The model to use",
              type: 3,
              required: false,
              choices: @model_choices
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
        %Interaction{user: %User{id: user_id}},
        _middleware_data
      ) do
    api_key = Config.openai_api_key()
    url = "https://api.openai.com/v1/chat/completions"
    headers = [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{api_key}"}]

    behavior = find_option_value(other_options, "behavior")
    model = find_option_value(other_options, "model") || Enum.at(@model_choices, 0)

    messages = [
      %{role: "user", content: prompt}
    ]

    messages =
      if behavior do
        [%{role: "system", content: behavior} | messages]
      else
        messages
      end

    body =
      %{
        model: "gpt-3.5-turbo",
        user: Integer.to_string(user_id),
        presence_penalty: 0.5,
        frequency_penalty: 0.5,
        messages: messages
      }
      |> Jason.encode!()

    response_tuple =
      :post
      |> Finch.build(url, headers, body)
      |> Finch.request(FinchPool, receive_timeout: 120_000)

    case response_tuple do
      {:ok, response} ->
        chat_response =
          response
          |> Map.fetch!(:body)
          |> Jason.decode!()
          |> Map.fetch!("choices")
          |> Enum.at(0)
          |> Map.fetch!("message")
          |> Map.fetch!("content")

        prompt_field = %{name: "Prompt", value: Designer.code_block(prompt)}
        model_field = %{name: "Model", value: Designer.code_block(model)}

        fields =
          if behavior do
            behavior_field = %{name: "Behavior", value: Designer.code_block(behavior)}
            [prompt_field, behavior_field, model_field]
          else
            [prompt_field, model_field]
          end

        options = [
          title: nil,
          description: chat_response,
          fields: fields
        ]

        {:success, options}

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:warning,
         "Could not generate a response in time. Prompt was likely too complex or long to process."}
    end
  end
end
