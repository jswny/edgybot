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

  defp make_interaction(data) do
    struct(Interaction, id: System.unique_integer([:positive]), data: data)
  end

  defp make_data(name, opts \\ [], resolved \\ nil) do
    struct(ApplicationCommandInteractionData,
      id: System.unique_integer([:positive]),
      name: name,
      type: 1,
      options: opts,
      resolved: resolved
    )
  end

  defp make_opt(name, type, value, child_opts \\ nil) do
    struct(ApplicationCommandInteractionDataOption,
      name: name,
      type: type,
      value: value,
      options: child_opts
    )
  end

  describe "parse_interaction/1" do
    test "parses simple top-level command" do
      data = make_data("ping")
      inter = make_interaction(data)

      {names, opts} = InteractionHandler.parse_interaction(inter)

      assert names == ["ping"]
      assert opts == %{}
    end

    test "parses nested command with attachment + prompt" do
      att_id = 123_456
      att = struct(Attachment, id: att_id, filename: "hat.png", url: "https://ex.com/hat.png")

      resolved =
        struct(ApplicationCommandInteractionDataResolved,
          attachments: %{att_id => att}
        )

      prompt_opt = make_opt("prompt", 3, "make him wear a hat")
      img_opt = make_opt("image", 11, att_id)
      sub_opt = make_opt("edit", 1, nil, [prompt_opt, img_opt])
      data = make_data("image", [sub_opt], resolved)
      inter = make_interaction(data)

      {names, opts} = InteractionHandler.parse_interaction(inter)

      assert names == ["image", "edit"]
      assert opts == %{"prompt" => "make him wear a hat", "image" => att}
    end

    test "resolves USER option to merged user/member map" do
      uid = 42
      user = struct(User, id: uid, username: "joe", discriminator: "0001")
      memb = struct(Member, user_id: uid, nick: "Joe", roles: [])

      resolved =
        struct(ApplicationCommandInteractionDataResolved,
          users: %{uid => user},
          members: %{uid => memb}
        )

      tgt_opt = make_opt("target", 6, uid)
      sub_opt = make_opt("ban", 1, nil, [tgt_opt])
      data = make_data("mod", [sub_opt], resolved)
      inter = make_interaction(data)

      {_names, opts} = InteractionHandler.parse_interaction(inter)
      merged = opts["target"]

      assert merged.id == uid
      assert merged.nick == "Joe"
      assert merged.username == "joe"
    end

    test "resolves MENTIONABLE option to role when role supplied" do
      rid = 555
      role = struct(Role, id: rid, name: "Admin")

      resolved =
        struct(ApplicationCommandInteractionDataResolved,
          roles: %{rid => role}
        )

      tgt_opt = make_opt("who", 9, rid)
      data = make_data("give-role", [tgt_opt], resolved)
      inter = make_interaction(data)

      {_names, opts} = InteractionHandler.parse_interaction(inter)
      assert opts["who"] == role
    end

    test "resolves CHANNEL option correctly" do
      cid = 777
      chan = struct(Channel, id: cid, name: "general")

      resolved =
        struct(ApplicationCommandInteractionDataResolved,
          channels: %{cid => chan}
        )

      ch_opt = make_opt("channel", 7, cid)
      data = make_data("move", [ch_opt], resolved)
      inter = make_interaction(data)

      {_names, opts} = InteractionHandler.parse_interaction(inter)
      assert opts["channel"] == chan
    end

    test "passes through primitive value when no resolution needed" do
      int_opt = make_opt("count", 4, 10)
      data = make_data("repeat", [int_opt])
      inter = make_interaction(data)

      {_names, opts} = InteractionHandler.parse_interaction(inter)
      assert opts == %{"count" => 10}
    end

    test "maintains correct order with three-level nesting" do
      leaf_opt = make_opt("value", 3, "ok")
      sub_opt = make_opt("blur", 1, nil, [leaf_opt])
      grp_opt = make_opt("filters", 1, nil, [sub_opt])
      data = make_data("image", [grp_opt])
      inter = make_interaction(data)

      {names, _opts} = InteractionHandler.parse_interaction(inter)
      assert names == ["image", "filters", "blur"]
    end
  end
end
