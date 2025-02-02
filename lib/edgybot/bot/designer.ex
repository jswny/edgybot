defmodule Edgybot.Bot.Designer do
  @moduledoc false

  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field

  @type options() :: [option]

  @type image_option() :: binary() | {:file, binary()}

  @type option() ::
          {:title, Embed.title()}
          | {:description, Embed.description()}
          | {:fields, [field_options()]}
          | {:stacktrace, Exception.stacktrace()}
          | {:image, image_option()}

  @type field_options() :: %{
          name: Field.name(),
          value: Field.value(),
          inline?: Field.inline()
        }

  @zero_width_space "​"

  def color_green, do: 3_066_993

  def color_orange, do: 16_227_348

  def color_red, do: 16_734_003

  def emoji_yes, do: "✅"

  def emoji_no, do: "⛔"

  def success_embed(options \\ []) when is_list(options) do
    default_options = %{title: "Success"}
    build_embed(color_green(), options, default_options)
  end

  def warning_embed(options \\ []) when is_list(options) do
    default_options = %{title: "Warning"}
    build_embed(color_orange(), options, default_options)
  end

  def error_embed(options \\ []) when is_list(options) do
    default_options = %{title: "Error"}
    build_embed(color_red(), options, default_options)
  end

  def code_block(content, escape? \\ true) when is_binary(content) and is_boolean(escape?),
    do: render_code("```", content, escape?)

  def code_inline(content, escape? \\ true) when is_binary(content) and is_boolean(escape?),
    do: render_code("``", content, escape?)

  defp render_code(encloser, content, escape?) when is_binary(encloser) and is_binary(content) and is_boolean(escape?) do
    content =
      if escape? do
        String.replace(content, "`", "`#{@zero_width_space}")
      else
        content
      end

    "#{encloser}#{content}#{encloser}"
  end

  defp build_embed(color, options, default_options)
       when is_integer(color) and is_list(options) and is_map(default_options) do
    merged_options =
      options
      |> Enum.into(default_options)
      |> Map.new(fn {option, value} ->
        case value do
          :none -> {option, nil}
          _ -> {option, value}
        end
      end)

    %Embed{}
    |> Embed.put_color(color)
    |> embed_title(Map.get(merged_options, :title))
    |> embed_description(Map.get(merged_options, :description))
    |> embed_fields(Map.get(merged_options, :fields))
    |> embed_stacktrace(Map.get(merged_options, :stacktrace))
    |> embed_image(Map.get(merged_options, :image))
    |> embed_url(Map.get(merged_options, :url))
  end

  defp embed_title(%Embed{} = embed, title) when is_binary(title), do: Embed.put_title(embed, title)

  defp embed_title(%Embed{} = embed, nil), do: embed

  defp embed_description(%Embed{} = embed, description) when is_binary(description),
    do: Embed.put_description(embed, description)

  defp embed_description(%Embed{} = embed, nil), do: embed

  defp embed_fields(%Embed{} = embed, [%{name: name, value: nil} | rest]) when is_binary(name) and is_list(rest),
    do: embed_fields(embed, rest)

  defp embed_fields(%Embed{} = embed, [%{name: name, value: value} = field | rest])
       when is_binary(name) and is_binary(value) and is_list(rest) do
    inline? = Map.get(field, :inline, false)

    embed
    |> Embed.put_field(name, value, inline?)
    |> embed_fields(rest)
  end

  defp embed_fields(%Embed{} = embed, []), do: embed

  defp embed_fields(%Embed{} = embed, nil), do: embed

  defp embed_stacktrace(%Embed{} = embed, stacktrace) when is_list(stacktrace) do
    formatted_stacktrace = Exception.format_stacktrace(stacktrace)
    Embed.put_field(embed, "Stacktrace", code_block(formatted_stacktrace))
  end

  defp embed_stacktrace(%Embed{} = embed, nil), do: embed

  defp embed_image(%Embed{} = embed, image_url) when is_binary(image_url), do: Embed.put_image(embed, image_url)

  defp embed_image(%Embed{} = embed, nil), do: embed

  defp embed_url(%Embed{} = embed, url) when is_binary(url), do: Embed.put_url(embed, url)

  defp embed_url(%Embed{} = embed, nil), do: embed
end
