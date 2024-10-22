defmodule Edgybot.Bot.Discord do
  alias Nostrum.Api
  alias Edgybot.OpenAI

  @message_type_reply 19

  def get_messages(
        guild_id,
        channel_id,
        num_messages,
        batch_size,
        allowed_message_types,
        allowed_user_ids
      )
      when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and
             is_integer(batch_size) and is_list(allowed_message_types) and
             is_list(allowed_user_ids),
      do:
        get_messages(
          guild_id,
          channel_id,
          num_messages,
          batch_size,
          allowed_message_types,
          allowed_user_ids,
          {}
        )

  def get_messages(
        guild_id,
        channel_id,
        num_messages,
        batch_size,
        allowed_message_types,
        allowed_user_ids,
        locator
      )
      when is_integer(guild_id) and is_integer(channel_id) and is_integer(num_messages) and
             is_integer(batch_size) and is_list(allowed_message_types) and
             is_list(allowed_user_ids) and is_tuple(locator) do
    all_messages =
      channel_id
      |> Api.get_channel_messages!(batch_size, locator)

    filtered_messages =
      all_messages
      |> Enum.filter(fn message ->
        # TODO: let callers pass in custom message filters
        message.author.bot != true &&
          message.type in allowed_message_types &&
          message.author.id in allowed_user_ids &&
          message.content != nil &&
          message.content != "" &&
          case message do
            %{type: @message_type_reply, referenced_message: nil} -> false
            %{type: @message_type_reply, referenced_message: %{content: nil}} -> false
            %{type: @message_type_reply, referenced_message: %{content: ""}} -> false
            _ -> true
          end
      end)
      |> Enum.map(fn message ->
        member = Api.get_guild_member!(guild_id, message.author.id)

        # TODO: move this elsewhere, is it even openai specific? yeah I guess so but it shouldn't be called here
        sanitized_nick = OpenAI.sanitize_chat_message_name(member.nick, message.author.username)

        parent_message = message.referenced_message.content

        # TODO: don't reformat messages
        %{
          role: "user",
          name: sanitized_nick,
          content: message.content,
          parent_message: parent_message
        }
      end)

    num_filtered_messages = Enum.count(filtered_messages)

    if num_filtered_messages < num_messages do
      new_num_messages = num_messages - num_filtered_messages

      earliest_message_id = List.last(all_messages).id

      get_messages(
        guild_id,
        channel_id,
        new_num_messages,
        batch_size,
        allowed_message_types,
        allowed_user_ids,
        {:before, earliest_message_id}
      ) ++
        filtered_messages
    else
      filtered_messages
    end
  end
end
