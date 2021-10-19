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
      description: "Set someone's nickname postfix",
      options: [
        %{
          name: "user",
          description: "The user to set the nickname for",
          type: 6,
          required: true
        },
        %{
          name: "postfix",
          description: "The postfix to set after the user's current nickname",
          type: 3,
          required: true
        }
      ]
    }
  end

  @impl true
  def handle_command(["nick"], [{"user", 6, %{id: user_id}}, {"postfix", 3, postfix}], %{
        guild_id: guild_id
      })
      when is_integer(user_id) and is_binary(postfix) and is_integer(guild_id) do
    {:ok, member} = Api.get_guild_member(guild_id, user_id)

    old_nick = Map.get(member, :nick, "")

    split_old_nick =
      old_nick
      |> String.split(@special_space, trim: true)
      |> Enum.map(fn str -> String.trim(str) end)

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

      result = Api.modify_guild_member(guild_id, user_id, nick: new_nick)

      case result do
        {:error,
         %Nostrum.Error.ApiError{
           response: %{code: 50_035, errors: %{nick: %{_errors: [%{message: error_message}]}}}
         }} ->
          handle_max_length_error(converted_postfix, error_message, base_nick, user_id)

        {:error, _error} ->
          raise "no"

        _ ->
          # {:ok} = result

          {:success, "Successfully set the nickname of #{Designer.user_mention(user_id)}"}
      end
    end
  end

  defp handle_max_length_error(postfix, error_message, base_nick, user_id)
       when is_binary(postfix) and is_binary(error_message) and is_binary(base_nick) and
              is_integer(user_id) do
    new_postfix_length =
      postfix
      |> String.length()
      |> Integer.to_string()

    allowable_length =
      ~r/^[^\d]*(\d+).*$/
      |> Regex.run(error_message)
      |> Enum.fetch!(1)

    max_new_postfix_length =
      allowable_length
      |> String.to_integer()
      |> Kernel.-(String.length(base_nick))
      |> Kernel.-(1)
      |> Integer.to_string()

    {:warning,
     "New nickname was too long to set for #{Designer.user_mention(user_id)}! New postfix length was #{Designer.code_inline(new_postfix_length)}. Maximum postfix length is #{Designer.code_inline(max_new_postfix_length)} (with the addition of 1 space)."}
  end

  defp convert_codepoint(104), do: ?ℎ

  defp convert_codepoint(codepoint) when codepoint in 64..90, do: codepoint - ?A + ?𝐴

  defp convert_codepoint(codepoint) when codepoint in 97..122, do: codepoint - ?a + ?𝑎

  defp convert_codepoint(codepoint) when is_integer(codepoint),
    do: codepoint
end
