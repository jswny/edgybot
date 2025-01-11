defmodule Edgybot.Bot.Plugin.ImagePlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin
  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Edgybot.External.Fal

  @impl true
  def get_plugin_definitions do
    model_choices = Config.fal_image_models()

    regular_model_choices =
      Enum.filter(model_choices, fn model -> !Map.get(model, "premium", false) end)

    premium_model_choices = reorder_premium_models(model_choices)

    regular_application_command =
      generate_application_command(
        "image",
        "",
        regular_model_choices
      )

    premium_application_command =
      generate_application_command(
        "image-p",
        "[Premium] ",
        premium_model_choices
      )

    [
      regular_application_command,
      premium_application_command
    ]
  end

  defp generate_application_command(
         name,
         description_prefix,
         model_choices,
         extra_options \\ []
       ) do
    default_options = [
      %{
        name: "prompt",
        description: "The prompt for the AI to respond to",
        type: 3,
        required: true
      },
      %{
        name: "model",
        description: "The model to use. Default: #{Enum.at(model_choices, 0)["name"]}",
        type: 3,
        required: false,
        choices: model_choices
      },
      %{
        name: "seed",
        description: "The seed to use for image generation.",
        type: 3,
        required: false
      }
    ]

    options = default_options ++ extra_options

    %{
      application_command: %{
        name: name,
        description: "#{description_prefix}Work with images using AI",
        type: 1,
        options: [
          %{
            name: "gen",
            description: "#{description_prefix}Generate an image using AI",
            type: 1,
            options: options
          }
        ]
      }
    }
  end

  @impl true
  def handle_interaction(
        ["image-p", "gen"],
        1,
        [{"prompt", 3, prompt} | other_options],
        _interaction,
        _middleware_data
      ) do
    available_models = Config.fal_image_models()

    default_model =
      available_models
      |> reorder_premium_models()
      |> Enum.at(0)
      |> Map.get("value")

    handle_interaction_matched(prompt, other_options, default_model)
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
    default_model = Enum.at(available_models, 0)["value"]
    handle_interaction_matched(prompt, other_options, default_model)
  end

  defp handle_interaction_matched(
         prompt,
         other_options,
         default_model
       ) do
    model = find_option_value(other_options, "model") || default_model
    seed = find_option_value(other_options, "seed")

    enable_safety_checker? =
      !Enum.any?(Config.fal_image_models_safety_checker_disable(), &String.contains?(model, &1))

    body =
      %{
        prompt: prompt,
        enable_safety_checker: enable_safety_checker?
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
            get_image(response_url, model, prompt)

          {:error, error} ->
            {:warning, error}
        end

      {:error, error} ->
        {:warning, error}
    end
  end

  defp get_image(response_url, model, prompt) do
    get_opts = [method: :get, base_url: nil, url: response_url]

    case Fal.call_and_handle_errors(get_opts) do
      {:ok,
       %{
         status: 200,
         body: %{"images" => [image | _]} = body
       }} ->
        image_url = image["url"]

        prompt_field = %{name: "Prompt", value: Designer.code_block(prompt)}
        model_field = %{name: "Model", value: Designer.code_inline(model), inline: true}

        fields = [prompt_field, model_field]

        seed = body["seed"]

        fields =
          if seed do
            seed_field = %{
              name: "Seed",
              value: seed |> Integer.to_string() |> Designer.code_inline(),
              inline: true
            }

            fields ++ [seed_field]
          else
            fields
          end

        options = [
          title: nil,
          image: image_url,
          fields: fields
        ]

        {:success, options}

      {:error, error} ->
        {:warning, Designer.code_block(error)}
    end
  end

  defp reorder_premium_models(models) do
    case Enum.find(models, fn model -> Map.get(model, "premium", false) end) do
      nil ->
        models

      match ->
        [match | List.delete(models, match)]
    end
  end
end
