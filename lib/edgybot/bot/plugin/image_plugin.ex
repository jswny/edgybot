defmodule Edgybot.Bot.Plugin.ImagePlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.Designer
  alias Edgybot.OpenAI
  alias Edgybot.Config

  alias Nostrum.Struct.{Interaction, User}

  @style_choices [
    %{name: "Vivid", value: "vivid"},
    %{name: "Natural", value: "natural"}
  ]

  @impl true
  def get_plugin_definitions do
    model_choices = Config.openai_image_models()
    size_choices = Config.openai_image_sizes()

    [
      %{
        application_command: %{
          name: "image",
          description: "Work with images using an AI",
          type: 1,
          options: [
            %{
              name: "gen",
              description: "Generate an image using AI",
              type: 1,
              options: [
                %{
                  name: "prompt",
                  description: "The prompt for the AI to respond to",
                  type: 3,
                  required: true
                },
                %{
                  name: "model",
                  description: "The model to use. Default: #{Enum.at(model_choices, 0).name}",
                  type: 3,
                  required: false,
                  choices: model_choices
                },
                %{
                  name: "style",
                  description:
                    "The style of the image to generate. Default: #{Enum.at(@style_choices, 0).name}",
                  type: 3,
                  required: false,
                  choices: @style_choices
                },
                %{
                  name: "size",
                  description:
                    "The size of the image to generate. Default: #{Enum.at(size_choices, 0).name}",
                  type: 3,
                  required: false,
                  choices: size_choices
                }
              ]
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["image", "gen"],
        1,
        [{"prompt", 3, prompt} | other_options],
        %Interaction{user: %User{id: user_id}},
        _middleware_data
      ) do
    available_models = Config.openai_image_models()
    available_sizes = Config.openai_image_sizes()
    model = find_option_value(other_options, "model") || Enum.at(available_models, 0).value
    size = find_option_value(other_options, "size") || Enum.at(available_sizes, 0).value
    style = find_option_value(other_options, "style") || Enum.at(@style_choices, 0).value

    body =
      %{
        size: size,
        style: style,
        prompt: prompt,
        model: model,
        response_format: "b64_json"
      }

    url = "https://api.openai.com/v1/images/generations"

    case OpenAI.call_and_handle_errors(url, body, user_id) do
      {:ok, response} ->
        image_response =
          response
          |> Map.fetch!("data")
          |> Enum.at(0)
          |> Map.fetch!("b64_json")
          |> Base.decode64!()

        prompt_field = %{name: "Prompt", value: Designer.code_block(prompt)}
        size_field = %{name: "Size", value: Designer.code_inline(size), inline: true}
        style_field = %{name: "Style", value: Designer.code_inline(style), inline: true}
        model_field = %{name: "Model", value: Designer.code_inline(model), inline: true}

        fields = [prompt_field, size_field, style_field, model_field]

        options = [
          title: nil,
          image: {:file, image_response},
          fields: fields
        ]

        {:success, options}

      {:error, message} ->
        {:warning, message}
    end
  end
end
