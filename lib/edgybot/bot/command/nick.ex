defmodule Edgybot.Bot.Command.Nick do
  @moduledoc false

  alias Edgybot.Bot.Designer
  alias Nostrum.Api

  @special_space " "

  @behaviour Edgybot.Bot.Command

  @impl true
  def get_command_definition do
    %{
      name: "nick",
      description: "Set or clear someone's nickname postfix",
      options: [
        %{
          name: "user",
          description: "The user to set or clear the nickname for",
          type: 6,
          required: true
        },
        %{
          name: "postfix",
          description: "The postfix to set",
          type: 3,
          required: false
        }
      ]
    }
  end

  @impl true
  def handle_command(["nick"], [{"user", 6, %{id: user_id}}], %{
        guild_id: guild_id
      })
      when is_integer(user_id) and is_integer(guild_id) do
    split_old_nick = get_and_split_nickname(guild_id, user_id)

    base_nick = Enum.fetch!(split_old_nick, 0)

    set_nickname_and_handle_response(guild_id, user_id, base_nick, "cleared")
  end

  @impl true
  def handle_command(["nick"], [{"user", 6, %{id: user_id}}, {"postfix", 3, postfix}], %{
        guild_id: guild_id
      })
      when is_integer(user_id) and is_binary(postfix) and is_integer(guild_id) do
    split_old_nick = get_and_split_nickname(guild_id, user_id)

    if Enum.empty?(split_old_nick) do
      {:warning, "Could not parse the base nickname for #{Designer.user_mention(user_id)}!"}
    else
      base_nick = Enum.fetch!(split_old_nick, 0)

      converted_postfix =
        postfix
        |> String.to_charlist()
        |> Enum.map(fn char -> convert_codepoint(char) end)
        |> List.to_string()

      new_nick = "#{base_nick}#{@special_space}#{converted_postfix}"

      set_nickname_and_handle_response(guild_id, user_id, new_nick, "set")
    end
  end

  defp get_and_split_nickname(guild_id, user_id)
       when is_integer(guild_id) and is_integer(user_id) do
    {:ok, member} = Api.get_guild_member(guild_id, user_id)

    old_nick = Map.get(member, :nick, "")

    old_nick
    |> String.split(@special_space, trim: true)
    |> Enum.map(fn str -> String.trim(str) end)
    |> Enum.reject(fn str -> String.trim(str) == "" end)
  end

  defp set_nickname_and_handle_response(guild_id, user_id, new_nickname, action)
       when is_integer(guild_id) and is_integer(user_id) and is_binary(new_nickname) and
              is_binary(action) do
    result = Api.modify_guild_member(guild_id, user_id, nick: new_nickname)

    case result do
      {:error,
       %Nostrum.Error.ApiError{
         response: %{code: 50_035, errors: %{nick: %{_errors: [%{message: error_message}]}}}
       }} ->
        handle_max_length_error(user_id, new_nickname, error_message)

      _ ->
        {:ok} = result

        {:success, "Successfully #{action} the nickname of #{Designer.user_mention(user_id)}"}
    end
  end

  defp handle_max_length_error(user_id, new_nickname, error_message)
       when is_integer(user_id) and is_binary(new_nickname) and is_binary(error_message) do
    new_length =
      new_nickname
      |> String.length()
      |> Integer.to_string()

    max_length =
      ~r/^[^\d]*(\d+).*$/
      |> Regex.run(error_message)
      |> Enum.fetch!(1)

    {:warning,
     "New nickname was too long to set for #{Designer.user_mention(user_id)}! New length was #{Designer.code_inline(new_length)}. Maximum length is #{Designer.code_inline(max_length)}."}
  end

  defp convert_codepoint(104), do: ?ℎ

  defp convert_codepoint(codepoint) when codepoint in 64..90, do: codepoint - ?A + ?𝐴

  defp convert_codepoint(codepoint) when codepoint in 97..122, do: codepoint - ?a + ?𝑎

  defp convert_codepoint(codepoint) when is_integer(codepoint),
    do: codepoint
end
