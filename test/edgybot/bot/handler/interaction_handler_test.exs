defmodule Edgybot.Bot.Handler.InteractionHandlerTest do
  use ExUnit.Case, async: true

  alias Edgybot.Bot.Handler.InteractionHandler
  alias Nostrum.Struct.ApplicationCommandInteractionData
  alias Nostrum.Struct.ApplicationCommandInteractionDataOption
  alias Nostrum.Struct.ApplicationCommandInteractionDataResolved
  alias Nostrum.Struct.Channel
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.Interaction
  alias Nostrum.Struct.Message.Attachment
  alias Nostrum.Struct.User

  defp create_interaction(interaction_data) do
    struct(Interaction,
      id: System.unique_integer([:positive]),
      data: interaction_data
    )
  end

  defp create_application_command_interaction_data(command_name, options_list \\ [], resolved_data \\ nil) do
    struct(ApplicationCommandInteractionData,
      id: System.unique_integer([:positive]),
      name: command_name,
      type: 1,
      options: options_list,
      resolved: resolved_data
    )
  end

  defp create_application_command_interaction_data_option(option_name, option_type, option_value, nested_options \\ nil) do
    struct(ApplicationCommandInteractionDataOption,
      name: option_name,
      type: option_type,
      value: option_value,
      options: nested_options
    )
  end

  describe "parse_interaction/1" do
    test "parses simple top-level command" do
      command_data = create_application_command_interaction_data("ping")
      interaction_struct = create_interaction(command_data)

      {name_sequence, options_map} = InteractionHandler.parse_interaction(interaction_struct)

      assert name_sequence == ["ping"]
      assert options_map == %{}
    end

    test "parses nested command with attachment and prompt" do
      attachment_identifier = 123_456

      attachment_struct =
        struct(Attachment,
          id: attachment_identifier,
          filename: "hat.png",
          url: "https://ex.com/hat.png"
        )

      resolved_data =
        struct(ApplicationCommandInteractionDataResolved,
          attachments: %{attachment_identifier => attachment_struct}
        )

      prompt_option =
        create_application_command_interaction_data_option("prompt", 3, "make him wear a hat")

      image_option =
        create_application_command_interaction_data_option("image", 11, attachment_identifier)

      edit_option =
        create_application_command_interaction_data_option("edit", 1, nil, [prompt_option, image_option])

      command_data =
        create_application_command_interaction_data("image", [edit_option], resolved_data)

      interaction_struct = create_interaction(command_data)

      {name_sequence, options_map} = InteractionHandler.parse_interaction(interaction_struct)

      assert name_sequence == ["image", "edit"]
      assert options_map == %{"prompt" => "make him wear a hat", "image" => attachment_struct}
    end

    test "resolves USER option to merged user and member data" do
      user_identifier = 42

      user_struct =
        struct(User,
          id: user_identifier,
          username: "joe",
          discriminator: "0001"
        )

      member_struct =
        struct(Member,
          user_id: user_identifier,
          nick: "Joe",
          roles: []
        )

      resolved_data =
        struct(ApplicationCommandInteractionDataResolved,
          users: %{user_identifier => user_struct},
          members: %{user_identifier => member_struct}
        )

      target_option =
        create_application_command_interaction_data_option("target", 6, user_identifier)

      ban_option =
        create_application_command_interaction_data_option("ban", 1, nil, [target_option])

      command_data =
        create_application_command_interaction_data("mod", [ban_option], resolved_data)

      interaction_struct = create_interaction(command_data)

      {_name_sequence, options_map} = InteractionHandler.parse_interaction(interaction_struct)
      merged_user_member = options_map["target"]

      assert merged_user_member.id == user_identifier
      assert merged_user_member.nick == "Joe"
      assert merged_user_member.username == "joe"
    end

    test "resolves MENTIONABLE option to role when role provided" do
      role_identifier = 555

      role_struct =
        struct(Role,
          id: role_identifier,
          name: "Admin"
        )

      resolved_data =
        struct(ApplicationCommandInteractionDataResolved,
          roles: %{role_identifier => role_struct}
        )

      who_option =
        create_application_command_interaction_data_option("who", 9, role_identifier)

      command_data =
        create_application_command_interaction_data("give-role", [who_option], resolved_data)

      interaction_struct = create_interaction(command_data)

      {_name_sequence, options_map} = InteractionHandler.parse_interaction(interaction_struct)
      assert options_map["who"] == role_struct
    end

    test "resolves CHANNEL option correctly" do
      channel_identifier = 777

      channel_struct =
        struct(Channel,
          id: channel_identifier,
          name: "general"
        )

      resolved_data =
        struct(ApplicationCommandInteractionDataResolved,
          channels: %{channel_identifier => channel_struct}
        )

      channel_option =
        create_application_command_interaction_data_option("channel", 7, channel_identifier)

      command_data =
        create_application_command_interaction_data("move", [channel_option], resolved_data)

      interaction_struct = create_interaction(command_data)

      {_name_sequence, options_map} = InteractionHandler.parse_interaction(interaction_struct)
      assert options_map["channel"] == channel_struct
    end

    test "passes through primitive value when no resolution needed" do
      count_option =
        create_application_command_interaction_data_option("count", 4, 10)

      command_data =
        create_application_command_interaction_data("repeat", [count_option])

      interaction_struct = create_interaction(command_data)

      {_name_sequence, options_map} = InteractionHandler.parse_interaction(interaction_struct)
      assert options_map == %{"count" => 10}
    end

    test "maintains correct order with three-level nesting" do
      value_option =
        create_application_command_interaction_data_option("value", 3, "ok")

      blur_option =
        create_application_command_interaction_data_option("blur", 1, nil, [value_option])

      filters_option =
        create_application_command_interaction_data_option("filters", 1, nil, [blur_option])

      command_data =
        create_application_command_interaction_data("image", [filters_option])

      interaction_struct = create_interaction(command_data)

      {name_sequence, _options_map} = InteractionHandler.parse_interaction(interaction_struct)
      assert name_sequence == ["image", "filters", "blur"]
    end
  end
end
