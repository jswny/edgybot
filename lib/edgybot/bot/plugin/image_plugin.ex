defmodule Edgybot.Bot.Plugin.ImagePlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Edgybot.External.Fal

  @impl true
  def get_plugin_definitions do
    model_choices = Config.fal_image_models()
    size_choices = Config.fal_image_sizes()

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
                  name: "size",
                  description:
                    "The size of the image to generate. Default: #{Enum.at(size_choices, 0).name}",
                  type: 3,
                  required: false,
                  choices: size_choices
                },
                %{
                  name: "seed",
                  description: "The seed to use for image generation.",
                  type: 3,
                  required: false
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
        _interaction,
        _middleware_data
      ) do
    available_models = Config.fal_image_models()
    available_sizes = Config.fal_image_sizes()
    model = find_option_value(other_options, "model") || Enum.at(available_models, 0).value
    size = find_option_value(other_options, "size") || Enum.at(available_sizes, 0).value
    seed = find_option_value(other_options, "seed")

    body =
      %{
        image_size: size,
        prompt: prompt
      }

    body =
      if seed do
        Map.put(body, :seed, seed)
      else
        body
      end

    url = model

    create_opts = [method: :post, url: url, json: body]

    case Fal.call_and_handle_errors(create_opts) do
      {:ok, %{status: 200, body: %{"status_url" => status_url}}} ->
        status_opts =
          [
            base_url: nil,
            method: :get,
            url: status_url
          ]
          |> Fal.add_status_retry()

        case Fal.call_and_handle_errors(status_opts) do
          {:ok, %{status: 200, body: %{"response_url" => response_url}}} ->
            get_image(response_url, prompt, size, model)

          {:error, error} ->
            {:warning, error}
        end

      {:error, error} ->
        {:warning, error}
    end
  end

  defp get_image(response_url, prompt, size, model) do
    get_opts = [method: :get, base_url: nil, url: response_url]

    case Fal.call_and_handle_errors(get_opts) do
      {:ok,
       %{
         status: 200,
         body: %{"images" => images, "seed" => seed}
       }} ->
        image = Enum.at(images, 0)["url"]

        prompt_field = %{name: "Prompt", value: Designer.code_block(prompt)}
        size_field = %{name: "Size", value: Designer.code_inline(size), inline: true}
        model_field = %{name: "Model", value: Designer.code_inline(model), inline: true}

        seed_field = %{
          name: "Seed",
          value: seed |> Integer.to_string() |> Designer.code_inline(),
          inline: true
        }

        fields = [prompt_field, size_field, model_field, seed_field]

        options = [
          title: nil,
          image: image,
          fields: fields
        ]

        {:success, options}

      {:error, error} ->
        {:warning, error}
    end
  end
end
