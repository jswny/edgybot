defmodule Edgybot.Bot.Designer do
  @moduledoc false

  alias Nostrum.Struct.{Embed, User}
  alias Nostrum.Struct.Guild.Role

  @type options() :: [option]

  @type option() ::
          {:title, String.t()}
          | {:description, String.t()}
          | {:fields, [field_options()]}
          | {:stacktrace, Exception.stacktrace()}

  @type field_options() :: %{
          name: String.t(),
          value: String.t(),
          inline?: boolean()
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

  def role_mention(role_id) when is_integer(role_id) do
    Role.mention(%Role{
      id: role_id,
      color: 0,
      hoist: false,
      managed: false,
      mentionable: false,
      name: "",
      permissions: 0,
      position: 0
    })
  end

  def user_mention(user_id) when is_integer(user_id) do
    User.mention(%User{
      avatar: nil,
      bot: nil,
      discriminator: "",
      email: nil,
      id: user_id,
      mfa_enabled: nil,
      public_flags: %Nostrum.Struct.User.Flags{},
      username: "",
      verified: nil
    })
  end

  defp render_code(encloser, content, escape?)
       when is_binary(encloser) and is_binary(content) and is_boolean(escape?) do
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
    merged_options = Enum.into(options, default_options)

    %Embed{}
    |> Embed.put_color(color)
    |> embed_title(Map.get(merged_options, :title))
    |> embed_description(Map.get(merged_options, :description))
    |> embed_fields(Map.get(merged_options, :fields))
    |> embed_stacktrace(Map.get(merged_options, :stacktrace))
  end

  defp embed_title(embed, title) when is_map(embed) and is_binary(title),
    do: Embed.put_title(embed, title)

  defp embed_title(embed, nil) when is_map(embed), do: embed

  defp embed_description(embed, description) when is_map(embed) and is_binary(description),
    do: Embed.put_description(embed, description)

  defp embed_description(embed, nil) when is_map(embed), do: embed

  defp embed_fields(embed, [%{name: name, value: value} = field | rest])
       when is_map(embed) and is_binary(name) and is_binary(value) and is_list(rest) do
    inline? = Map.get(field, :inline?, false)

    embed
    |> Embed.put_field(name, value, inline?)
    |> embed_fields(rest)
  end

  defp embed_fields(embed, []) when is_map(embed) do
    embed
  end

  defp embed_fields(embed, nil) when is_map(embed), do: embed

  defp embed_stacktrace(embed, stacktrace) when is_map(embed) and is_list(stacktrace) do
    formatted_stacktrace = Exception.format_stacktrace(stacktrace)
    Embed.put_field(embed, "Stacktrace", code_block(formatted_stacktrace))
  end

  defp embed_stacktrace(embed, nil) when is_map(embed), do: embed
end
