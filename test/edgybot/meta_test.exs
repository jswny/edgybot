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

    test "create_user/1 with existing id returns error changeset" do
      user_fixture()
      attrs = user_valid_attrs()
      assert {:error, %Ecto.Changeset{} = changeset} = Meta.create_user(attrs)
      assert %{id: ["has already been taken"]} = errors_on(changeset)
    end
  end
end
