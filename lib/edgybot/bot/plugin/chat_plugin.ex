defmodule Edgybot.Bot.Plugin.ChatPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.{Designer, OpenAI}
  alias Edgybot.Config

  alias Nostrum.Struct.{Interaction, User}

  @impl true
  def get_plugin_definitions do
    model_choices = Config.openai_chat_models()

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
              choices: model_choices
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
    url = "https://api.openai.com/v1/chat/completions"
    available_models = Config.openai_chat_models()

    model =
      find_option_value(other_options, "model") || Enum.at(available_models, 0).value

    behavior = find_option_value(other_options, "behavior")

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
        model: model,
        presence_penalty: 0.5,
        frequency_penalty: 0.5,
        messages: messages
      }

    case OpenAI.call_and_handle_errors(url, body, user_id) do
      {:ok, response} ->
        chat_response =
          response
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

      {:error, message} ->
        {:warning, message}
    end
  end
end
