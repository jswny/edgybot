defmodule Edgybot.Bot.Plugin.MemePlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Edgybot.Config

  @impl true
  def get_plugin_definitions do
    meme_text_options =
      Enum.map(1..10, fn n ->
        %{
          name: "text-#{n}",
          description: "Text #{n} for the meme",
          type: 3,
          required: false
        }
      end)

    meme_overlay_options =
      Enum.map(1..10, fn n ->
        %{
          name: "overlay-#{n}",
          description: "Overlay image URL #{n} for the meme. Will be overridden by a style",
          type: 3,
          required: false
        }
      end)

    [
      %{
        application_command: %{
          name: "meme",
          description: "Generate memes",
          type: 1,
          options: [
            %{
              name: "search",
              description: "Search for a meme template",
              type: 1,
              options: [
                %{
                  name: "query",
                  description: "The meme template to search for",
                  type: 3,
                  required: true
                },
                %{
                  name: "animated",
                  description: "Search only for animated templates",
                  type: 5,
                  required: false
                }
              ]
            },
            %{
              name: "template",
              description: "Get the details for a specific template",
              type: 1,
              options: [
                %{
                  name: "id",
                  description: "The ID of the meme template to get",
                  type: 3,
                  required: true
                },
                %{
                  name: "style",
                  description: "The style to apply to the template",
                  type: 3,
                  required: false
                }
              ]
            },
            %{
              name: "make",
              description: "Make a meme",
              type: 1,
              options:
                List.flatten([
                  %{name: "id", description: "The ID of the meme template to use", type: 3, required: true},
                  meme_text_options,
                  meme_overlay_options,
                  %{
                    name: "style",
                    description: "The style to apply to the template. Will override any overlays",
                    type: 3,
                    required: false
                  }
                ])
            },
            %{
              name: "custom",
              description: "Make a meme with a custom image",
              type: 1,
              options: [
                %{
                  name: "image_url",
                  description: "The URL of the image to use for the meme",
                  type: 3,
                  required: true
                }
                | meme_text_options
              ]
            }
          ]
        },
        metadata: %{
          name: "meme",
          children: [
            %{
              name: "search",
              data: %{
                ephemeral: true
              }
            },
            %{
              name: "template",
              data: %{
                ephemeral: true
              }
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(["meme", "search"], 1, %{"query" => query} = options, _interaction, _middleware_data)
      when is_binary(query) do
    animated? = Map.get(options, "animated", false)

    template_results = search_templates(query, animated?)

    if Enum.count(template_results) <= 0 do
      {:warning, "No matching templates found!"}
    else
      results_content =
        Enum.map_join(template_results, "\n", fn template ->
          "#{template["name"]} (#{Designer.code_inline(template["id"])})"
        end)

      options = %{
        title: "Template Search Results",
        fields: [%{name: "Templates", value: results_content}]
      }

      {:success, options}
    end
  end

  @impl true
  def handle_interaction(["meme", "template"], 1, %{"id" => id} = options, _interaction, _middleware_data)
      when is_binary(id) do
    case get_template(id) do
      {:ok, template} ->
        id_text = Designer.code_inline(template["id"])

        num_text_lines = template["lines"]
        text_lines = Enum.map(1..num_text_lines, fn n -> "text#{Integer.to_string(n)}" end)

        style = Map.get(options, "style")
        example_meme_url = make_meme(id, text_lines, nil, style)

        styles = Map.get(template, "styles", [])

        styles =
          if Enum.any?(styles) do
            Enum.map_join(styles, ",", &Designer.code_inline/1)
          else
            "none"
          end

        overlays =
          template
          |> Map.get("overlays", 0)
          |> Integer.to_string()
          |> Designer.code_inline()

        details =
          "**ID**: #{id_text}\n**Textboxes**: #{template["lines"]}\n**Styles**: #{styles}\n**Overlays**: #{overlays}"

        options = %{
          title: template["name"],
          url: template["source"],
          image: example_meme_url,
          fields: [%{name: "Details", value: details}]
        }

        {:success, options}

      {:error, _reason} ->
        {:warning, "No matching templates found!"}
    end
  end

  @impl true
  def handle_interaction(["meme", "make"], 1, %{"id" => template_id} = options, _interaction, _middleware_data)
      when is_binary(template_id) do
    case get_template(template_id) do
      {:ok, template} ->
        style = Map.get(options, "style")

        matching_template_style =
          template
          |> Map.get("styles", [])
          |> Enum.any?(fn template_style -> template_style == style end)

        if style == nil or matching_template_style do
          text_lines = get_matching_numbered_options(options, "text")
          overlays = get_matching_numbered_options(options, "overlay")
          meme_url = make_meme(template_id, text_lines, overlays, style)

          options = %{
            title: :none,
            image: meme_url
          }

          {:success, options}
        else
          {:warning, "No matching style for the specified template!"}
        end

      {:error, _reason} ->
        {:warning, "No matching template found!"}
    end
  end

  @impl true
  def handle_interaction(["meme", "custom"], 1, %{"image_url" => image_url} = options, _interaction, _middleware_data)
      when is_binary(image_url) do
    text_lines = get_matching_numbered_options(options, "text")
    meme_url = make_custom_meme(image_url, text_lines)

    options = %{
      title: :none,
      image: meme_url
    }

    {:success, options}
  end

  defp search_templates(query, animated?) when is_binary(query) and is_boolean(animated?) do
    encoded_query = URI.encode(query)

    {:ok, %{body: body}} =
      Req.get("#{Config.memegen_url()}/templates?filter=#{encoded_query}&animated=#{animated?}")

    body
  end

  defp get_template(id) when is_binary(id) do
    encoded_id = URI.encode(id)

    result = Req.get("#{Config.memegen_url()}/templates/#{encoded_id}")

    case result do
      {:ok, %{status: 404}} ->
        {:error, :invalid_template_id}

      {:ok, response} ->
        {:ok, response.body}

      error ->
        error
    end
  end

  defp get_matching_numbered_options(options, name) when is_map(options) and is_binary(name) do
    options
    |> Enum.filter(fn {option_name, _value} -> String.starts_with?(option_name, name) end)
    |> Enum.sort_by(fn {option_name, _value} ->
      option_name
      |> String.replace("#{name}-", "")
      |> String.to_integer()
    end)
    |> Enum.map(fn {_name, value} -> value end)
  end

  defp make_meme(template_id, text_lines, overlays, style)
       when is_binary(template_id) and is_list(text_lines) and (is_list(overlays) or is_nil(overlays)) and
              (is_binary(style) or is_nil(style)) do
    encoded_id = URI.encode(template_id)

    body = %{
      "text" => text_lines,
      "redirect" => true
    }

    body =
      if style == nil do
        if overlays == nil do
          body
        else
          Map.put(body, "style", overlays)
        end
      else
        Map.put(body, "style", style)
      end

    {:ok, response} =
      Req.post("#{Config.memegen_url()}/templates/#{encoded_id}", json: body, redirect: false)

    meme_url =
      response.headers
      |> Map.fetch!("location")
      |> Enum.at(0)

    meme_url
  end

  defp make_custom_meme(image_url, text_lines) when is_binary(image_url) and is_list(text_lines) do
    body = %{
      "background" => image_url,
      "text" => text_lines,
      "redirect" => true
    }

    {:ok, response} =
      Req.post("#{Config.memegen_url()}/templates/custom", json: body, redirect: false)

    meme_url =
      response.headers
      |> Map.fetch!("location")
      |> Enum.at(0)

    meme_url
  end
end
