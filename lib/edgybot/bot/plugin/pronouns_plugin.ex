defmodule Edgybot.Bot.Plugin.PronounsPlugin do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Bot.Designer
  alias Nostrum.Api
  alias Nostrum.Struct.Emoji
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.Interaction

  @role_prefix "Pronouns: "

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "pronouns",
          description: "Manage your pronouns",
          type: 1,
          options: [
            %{
              name: "set",
              description:
                "Set or update your pronouns with an icon (uses your existing icon if you don't provide a new one)",
              type: 1,
              options: [
                %{
                  name: "pronoun1",
                  description: "The first pronoun, before the slash",
                  type: 3,
                  required: true
                },
                %{
                  name: "pronoun2",
                  description: "The second pronoun, after the slash",
                  type: 3,
                  required: true
                },
                %{
                  name: "emoji",
                  description: "Emoji icon",
                  type: 3,
                  required: false
                },
                %{
                  name: "image",
                  description: "Image icon",
                  type: 11,
                  required: false
                }
              ]
            },
            %{
              name: "remove",
              description: "Remove your current pronouns",
              type: 1
            }
          ]
        },
        metadata: %{
          name: "pronouns",
          data: %{
            ephemeral: true
          }
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["pronouns", "set"],
        1,
        %{"pronoun1" => pronoun1, "pronoun2" => pronoun2} = options,
        %Interaction{guild_id: guild_id, user: %{id: user_id}},
        _middleware_data
      )
      when is_binary(pronoun1) and is_binary(pronoun2) and is_map(options) and is_integer(user_id) and
             is_integer(guild_id) do
    image_option = Map.get(options, "image")
    emoji_value = Map.get(options, "emoji")

    roles = Api.get_guild_roles!(guild_id)

    existing_pronoun_roles = get_existing_pronoun_roles(roles, guild_id, user_id)

    highest_position_role_with_icon = get_highest_position_role_with_icon(roles)

    full_pronouns = "#{pronoun1}/#{pronoun2}"

    image_url =
      emoji_value
      |> get_emoji_struct()
      |> get_image_url(image_option)

    existing_pronoun_role = List.first(existing_pronoun_roles)

    case existing_pronoun_role do
      nil ->
        role_options =
          generate_role_options(full_pronouns, image_url, emoji_value, true)

        new_role = Api.create_guild_role(guild_id, role_options)

        response =
          handle_create_role_result(
            new_role,
            image_option,
            emoji_value,
            full_pronouns
          )

        case response do
          {:success, _} ->
            setup_new_role(
              new_role,
              guild_id,
              user_id,
              highest_position_role_with_icon
            )
        end

        response

      _ ->
        role_options = generate_role_options(full_pronouns, image_url, emoji_value, false)

        guild_id
        |> Api.modify_guild_role(existing_pronoun_role.id, role_options)
        |> handle_create_role_result(
          image_option,
          emoji_value,
          full_pronouns
        )
    end
  end

  @impl true
  def handle_interaction(
        ["pronouns", "remove"],
        1,
        _options,
        %Interaction{guild_id: guild_id, user: %{id: user_id}},
        _middleware_data
      )
      when is_integer(user_id) and is_integer(guild_id) do
    guild_id
    |> Api.get_guild_roles!()
    |> get_existing_pronoun_roles(guild_id, user_id)
    |> delete_roles(guild_id)

    {:success, "Successfully cleared pronouns!"}
  end

  defp delete_roles(roles, guild_id) when is_list(roles) and is_integer(guild_id) do
    Enum.each(roles, fn role ->
      Api.delete_guild_role!(guild_id, role.id)
    end)
  end

  defp get_existing_pronoun_roles(roles, guild_id, user_id)
       when is_integer(guild_id) and is_integer(user_id) and is_list(roles) do
    roles_by_id = Map.new(roles, fn role -> {role.id, role} end)

    guild_id
    |> Api.get_guild_member!(user_id)
    |> Map.fetch!(:roles)
    |> Enum.map(fn role_id -> Map.fetch!(roles_by_id, role_id) end)
    |> Enum.filter(fn role -> String.starts_with?(role.name, @role_prefix) end)
  end

  defp get_image_url(nil, nil), do: nil

  defp get_image_url(%Emoji{} = custom_emoji, _image_option), do: Emoji.image_url(custom_emoji)

  defp get_image_url(_custom_emoji, %{} = image_option), do: Map.get(image_option, :url)

  defp get_emoji_struct(nil), do: nil

  defp get_emoji_struct(content) when is_binary(content) do
    custom_emoji_fields = Regex.named_captures(~r/<a*:(?<name>.+):(?<id>\d+)>/, content)

    if custom_emoji_fields && custom_emoji_fields["id"] && custom_emoji_fields["name"] do
      %Emoji{name: custom_emoji_fields["name"], id: custom_emoji_fields["id"]}
    end
  end

  defp get_highest_position_role_with_icon(roles) when is_list(roles) do
    roles
    |> Enum.filter(fn role ->
      Map.get(role, :icon) != nil || Map.get(role, :unicode_emoji) != nil
    end)
    |> Enum.sort_by(fn role -> role.position end, :desc)
    |> List.first()
  end

  defp generate_role_options(pronouns, nil, nil, false) when is_binary(pronouns),
    do: %{name: "#{generate_full_role_name(pronouns)}"}

  defp generate_role_options(pronouns, nil, nil, true) when is_binary(pronouns),
    do: generate_role_options_with_emoji(pronouns, "🇵")

  defp generate_role_options(pronouns, nil, emoji, _default) when is_binary(pronouns) and is_binary(emoji),
    do: generate_role_options_with_emoji(pronouns, emoji)

  defp generate_role_options(pronouns, image_url, _emoji, _default) when is_binary(pronouns) and is_binary(image_url),
    do: generate_role_options_with_image_url(pronouns, image_url)

  defp generate_role_options_with_image_url(pronouns, image_url) when is_binary(pronouns) and is_binary(image_url) do
    {:ok, %{status: 200, headers: headers, body: body}} = Req.get(image_url)

    content_type =
      headers
      |> Map.fetch!("content-type")
      |> Enum.at(0)

    image_data = "data:#{content_type};base64,#{Base.encode64(body)}"

    %{name: "#{generate_full_role_name(pronouns)}", icon: image_data, unicode_emoji: nil}
  end

  defp generate_role_options_with_emoji(pronouns, emoji) when is_binary(pronouns) and is_binary(emoji) do
    %{name: "#{generate_full_role_name(pronouns)}", icon: nil, unicode_emoji: emoji}
  end

  defp generate_full_role_name(suffix) do
    "#{@role_prefix}#{suffix}"
  end

  defp handle_create_role_result(
         {:error,
          %{response: %{code: 50_035, errors: %{name: %{_errors: [%{message: "Must be " <> max_role_name_length}]}}}}},
         _image,
         _emoji,
         _pronouns
       ) do
    max_role_name_length = String.replace_suffix(max_role_name_length, " or fewer in length.", "")

    {:warning, "Generated role name is too long; must be #{Designer.code_inline(max_role_name_length)} or less."}
  end

  defp handle_create_role_result({:error, %{response: %{code: 10_014}}}, _image, emoji, _pronouns)
       when is_binary(emoji) do
    {:warning, "The emoji #{Designer.code_inline(emoji)} is invalid."}
  end

  defp handle_create_role_result(
         {:error,
          %{
            response: %{
              code: 50_035,
              errors: %{icon: %{_errors: [%{message: "File cannot be larger than " <> max_image_size}]}}
            }
          }},
         image,
         _emoji,
         _pronouns
       )
       when is_struct(image) do
    max_image_size = String.replace_suffix(max_image_size, ".", "")

    options = [
      title: "Warning",
      description: "The specified image was too large. The max image size is #{Designer.code_inline(max_image_size)}.",
      image: image.url
    ]

    {:warning, options}
  end

  defp handle_create_role_result({:error, %{response: %{code: 50_035, errors: %{icon: _}}}}, image, _emoji, _pronouns)
       when is_struct(image) do
    {:warning, "The file #{Designer.code_inline(image.filename)} is invalid."}
  end

  defp handle_create_role_result({:error, :timeout}, image, _emoji, _pronouns) when is_struct(image) do
    {:warning, "Timed out while attempting to upload file #{Designer.code_inline(image.filename)}"}
  end

  defp handle_create_role_result({:ok, %Role{}}, _image, _emoji, pronouns) when is_binary(pronouns) do
    {:success, "Set pronouns to #{Designer.code_inline(pronouns)}"}
  end

  defp setup_new_role({:ok, %Role{id: new_role_id}}, guild_id, user_id, highest_position_role_with_icon)
       when is_integer(guild_id) and is_integer(user_id) and is_integer(new_role_id) and
              is_struct(highest_position_role_with_icon) do
    {:ok} = Api.add_guild_member_role(guild_id, user_id, new_role_id)

    Api.modify_guild_role_positions!(guild_id, [
      %{
        id: new_role_id,
        position: highest_position_role_with_icon.position + 1
      }
    ])
  end
end
