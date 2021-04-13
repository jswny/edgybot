defmodule Edgybot.MetaTest do
  use Edgybot.DataCase
  alias Edgybot.Meta

  describe "users" do
    alias Edgybot.Meta.User

    test "create_user/1 with valid data creates a user" do
      attrs = user_valid_attrs()
      assert {:ok, %User{}} = Meta.create_user(attrs)
    end

    test "create_user/1 with invalid data returns error changeset" do
      attrs = user_invalid_attrs()
      assert {:error, %Ecto.Changeset{}} = Meta.create_user(attrs)
    end

    test "create_user/1 with invalid snowflake ID returns error changeset" do
      attrs = user_valid_attrs(%{id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_user(attrs)
      assert %{id: ["invalid snowflake"]} = errors_on(changeset)
    end

    test "create_user/1 with existing ID returns error changeset" do
      fixture = user_fixture()
      attrs = user_valid_attrs(%{id: fixture.id})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_user(attrs)
      assert %{id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "messages" do
    alias Edgybot.Meta.Message

    test "create_message/1 with valid data creates a message" do
      attrs = message_valid_attrs()
      assert {:ok, %Message{}} = Meta.create_message(attrs)
    end

    test "create_message/1 with invalid data returns error changeset" do
      attrs = message_invalid_attrs()
      assert {:error, %Ecto.Changeset{}} = Meta.create_message(attrs)
    end

    test "create_message/1 with invalid snowflake ID returns error changeset" do
      attrs = message_valid_attrs(%{id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_message(attrs)
      assert %{id: ["invalid snowflake"]} = errors_on(changeset)
    end

    test "create_message/1 with invalid user ID returns error changeset" do
      attrs = message_valid_attrs(%{user_id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_message(attrs)
      assert %{user: ["does not exist"]} = errors_on(changeset)
    end

    test "create_message/1 with existing ID returns error changeset" do
      fixture = message_fixture()
      attrs = message_valid_attrs(%{id: fixture.id})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_message(attrs)
      assert %{id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "guilds" do
    alias Edgybot.Meta.Guild

    test "create_guild/1 with valid data creates a guild" do
      attrs = guild_valid_attrs()
      assert {:ok, %Guild{}} = Meta.create_guild(attrs)
    end

    test "create_guild/1 with invalid data returns error changeset" do
      attrs = guild_invalid_attrs()
      assert {:error, %Ecto.Changeset{}} = Meta.create_guild(attrs)
    end

    test "create_guild/1 with invalid snowflake ID returns error changeset" do
      attrs = guild_valid_attrs(%{id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_guild(attrs)
      assert %{id: ["invalid snowflake"]} = errors_on(changeset)
    end

    test "create_guild/1 with existing ID returns error changeset" do
      fixture = guild_fixture()
      attrs = guild_valid_attrs(%{id: fixture.id})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_guild(attrs)
      assert %{id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "channels" do
    alias Edgybot.Meta.Channel

    test "create_channel/1 with valid data creates a channel" do
      attrs = channel_valid_attrs()
      assert {:ok, %Channel{}} = Meta.create_channel(attrs)
    end

    test "create_channel/1 with invalid data returns error changeset" do
      attrs = channel_invalid_attrs()
      assert {:error, %Ecto.Changeset{}} = Meta.create_channel(attrs)
    end

    test "create_channel/1 with invalid snowflake ID returns error changeset" do
      attrs = channel_valid_attrs(%{id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_channel(attrs)
      assert %{id: ["invalid snowflake"]} = errors_on(changeset)
    end

    test "create_channel/1 with invalid guild ID returns error changeset" do
      attrs = channel_valid_attrs(%{guild_id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_channel(attrs)
      assert %{guild: ["does not exist"]} = errors_on(changeset)
    end

    test "create_channel/1 with existing ID returns error changeset" do
      fixture = channel_fixture()
      attrs = channel_valid_attrs(%{id: fixture.id})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_channel(attrs)
      assert %{id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "emoji" do
    alias Edgybot.Meta.Emoji

    test "create_emoji/1 with valid data creates a emoji" do
      attrs = emoji_valid_attrs()
      assert {:ok, %Emoji{}} = Meta.create_emoji(attrs)
    end

    test "create_emoji/1 with invalid data returns error changeset" do
      attrs = emoji_invalid_attrs()
      assert {:error, %Ecto.Changeset{}} = Meta.create_emoji(attrs)
    end

    test "create_emoji/1 with invalid snowflake ID returns error changeset" do
      attrs = emoji_valid_attrs(%{id: -1})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_emoji(attrs)
      assert %{id: ["invalid snowflake"]} = errors_on(changeset)
    end

    test "create_emoji/1 with existing ID returns error changeset" do
      fixture = emoji_fixture()
      attrs = emoji_valid_attrs(%{id: fixture.id})
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_emoji(attrs)
      assert %{id: ["has already been taken"]} = errors_on(changeset)
    end
  end
end
