defmodule Edgybot.Bot.Plugin.ImagePlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Edgybot.Config
  alias Edgybot.External.Fal

  @impl true
  def get_plugin_definitions do
    {regular_model_choices_generate, premium_model_choices_generate} =
      generate_model_choice_tiers(Config.fal_image_models_generate())

    {regular_model_choices_edit, premium_model_choices_edit} =
      generate_model_choice_tiers(Config.fal_image_models_edit())

    regular_application_command =
      generate_application_command(
        "image",
        "",
        regular_model_choices_generate,
        regular_model_choices_edit
      )

    premium_application_command =
      generate_application_command(
        "image-p",
        "[Premium] ",
        premium_model_choices_generate,
        premium_model_choices_edit
      )

    [
      regular_application_command,
      premium_application_command
    ]
  end

  @impl true
  def handle_interaction(["image-p", "gen"], 1, [{"prompt", 3, prompt} | other_options], _interaction, _middleware_data) do
    available_models = Config.fal_image_models_generate()

    default_model =
      available_models
      |> reorder_premium_models()
      |> Enum.at(0)
      |> Map.get("value")

    handle_image_gen(prompt, other_options, default_model)
  end

  @impl true
  def handle_interaction(["image", "gen"], 1, [{"prompt", 3, prompt} | other_options], _interaction, _middleware_data) do
    available_models = Config.fal_image_models_generate()
    default_model = Enum.at(available_models, 0)["value"]

    handle_image_gen(prompt, other_options, default_model)
  end

  @impl true
  def handle_interaction(
        ["image-p", "edit"],
        1,
        [{"prompt", 3, prompt}, {"image", 11, image_attachment} | other_options],
        _interaction,
        _middleware_data
      ) do
    available_models = Config.fal_image_models_edit()

    default_model =
      available_models
      |> reorder_premium_models()
      |> Enum.at(0)
      |> Map.get("value")

    handle_image_edit(prompt, image_attachment, other_options, default_model)
  end

  @impl true
  def handle_interaction(
        ["image", "edit"],
        1,
        [{"prompt", 3, prompt}, {"image", 11, image_attachment} | other_options],
        _interaction,
        _middleware_data
      ) do
    available_models = Config.fal_image_models_edit()
    default_model = Enum.at(available_models, 0)["value"]

    handle_image_edit(prompt, image_attachment, other_options, default_model)
  end

  defp handle_image_edit(prompt, image_attachment, other_options, default_model) do
    model = find_option_value(other_options, "model") || default_model
    seed = find_option_value(other_options, "seed")

    image_url = image_attachment.url

    body =
      %{
        prompt: prompt,
        image_url: image_url
      }

    body =
      if seed do
        Map.put(body, :seed, seed)
      else
        body
      end

    case Fal.create_and_wait_for_image(model, body) do
      {:ok, response} ->
        create_response_embed(response, model, prompt)

      {:error, error} ->
        {:warning, Designer.code_block(error)}
    end
  end

  defp handle_image_gen(prompt, other_options, default_model) do
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

    case Fal.create_and_wait_for_image(model, body) do
      {:ok, response} ->
        create_response_embed(response, model, prompt)

      {:error, error} ->
        {:warning, Designer.code_block(error)}
    end
  end

  defp create_response_embed(%{"images" => [image | _]} = response, model, prompt) do
    prompt_field = %{name: "Prompt", value: Designer.code_block(prompt)}
    model_field = %{name: "Model", value: Designer.code_inline(model), inline: true}

    fields = [prompt_field, model_field]

    image_url = image["url"]
    seed = response["seed"]

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
  end

  defp reorder_premium_models(models) do
    case Enum.find(models, fn model -> Map.get(model, "premium", false) end) do
      nil ->
        models

      match ->
        [match | List.delete(models, match)]
    end
  end

  defp generate_model_choice_tiers(model_choices) do
    regular_model_choices =
      Enum.filter(model_choices, fn model -> !Map.get(model, "premium", false) end)

    premium_model_choices = reorder_premium_models(model_choices)

    {regular_model_choices, premium_model_choices}
  end

  defp generate_application_command(name, description_prefix, generate_model_choices, edit_model_choices) do
    prompt_option = %{
      name: "prompt",
      description: "The prompt for the AI to respond to",
      type: 3,
      required: true
    }

    seed_option =
      %{
        name: "seed",
        description: "The seed to use for image generation",
        type: 3,
        required: false
      }

    generate_model_option = create_model_option(generate_model_choices)
    edit_model_option = create_model_option(edit_model_choices)

    image_option = %{
      name: "image",
      description: "The image to edit",
      type: 11,
      required: true
    }

    strength_option = %{
      name: "strength",
      description: "Strength of the input image in the edit",
      type: 10,
      required: false,
      min_value: 0,
      max_value: 1
    }

    generate_options = [prompt_option, generate_model_option, seed_option]
    edit_options = [prompt_option, image_option, edit_model_option, strength_option, seed_option]

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
            options: generate_options
          },
          %{
            name: "edit",
            description: "#{description_prefix}Edit an image using AI",
            type: 1,
            options: edit_options
          }
        ]
      }
    }
  end

  defp create_model_option(model_choices) do
    %{
      name: "model",
      description: "The model to use. Default: #{Enum.at(model_choices, 0)["name"]}",
      type: 3,
      required: false,
      choices: model_choices
    }
  end
end
