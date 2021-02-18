defmodule Edgybot.Bot.Handler.Response do
  @moduledoc false

  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @color_red 16_734_003
  @create_message_error "failed to send message"

  def handle_response(:noop, _source), do: :noop

  def handle_response(
        {:error, reason} = response,
        %{
          content: content,
          channel_id: channel_id,
          author: %{id: user_id}
        } = context
      )
      when is_binary(reason) and is_binary(content) and
             is_integer(channel_id) and
             is_integer(user_id) do
    handle_error_response(response, context)
  end

  def handle_response(
        {:error, reason, stacktrace} = response,
        %{
          content: content,
          channel_id: channel_id,
          author: %{id: user_id}
        } = context
      )
      when is_binary(reason) and is_binary(content) and
             is_list(stacktrace) and
             is_integer(channel_id) and is_integer(user_id) do
    handle_error_response(response, context)
  end

  def handle_response({:message, content_or_opts}, %{
        content: content,
        channel_id: channel_id,
        guild_id: guild_id,
        author: %{id: user_id}
      })
      when is_binary(content) and is_integer(channel_id) and is_integer(user_id) do
    response = {:message, channel_id, content_or_opts}
    contextual_source = generate_contextual_source(content, guild_id, channel_id)
    send_response_with_fallback(response, user_id, contextual_source)
  end

  defp handle_error_response(response, %{
         content: content,
         channel_id: channel_id,
         guild_id: guild_id,
         author: %{id: user_id}
       })
       when is_binary(content) and is_integer(channel_id) do
    contextual_response =
      case response do
        {:error, reason} ->
          contextual_source = generate_contextual_source(content, guild_id, channel_id)
          {:error, reason, contextual_source}

        {:error, reason, stacktrace} ->
          contextual_source = generate_contextual_source(content, guild_id, channel_id)
          {:error, reason, contextual_source, stacktrace}
      end

    contextual_source = elem(contextual_response, 2)
    embed = build_error_embed(contextual_response)
    new_response = {:message, channel_id, embed: embed}
    send_response_with_fallback(new_response, user_id, contextual_source)
  end

  defp send_response_with_fallback(
         {:message, _channel_id, content_or_opts} = response,
         fallback_user_id,
         source
       )
       when is_tuple(response) and is_integer(fallback_user_id) and is_binary(source) do
    send_response(response)
    |> case do
      {:ok, _message} ->
        :noop

      {:error, @create_message_error} ->
        fallback_error_response =
          {:error,
           "Failed to send message in channel. Check channel permissions. Falling back to DM",
           source}

        fallback_embed = build_error_embed(fallback_error_response)
        fallback_response = {:dm, fallback_user_id, embed: fallback_embed}
        send_response(fallback_response)

        send_response({:dm, fallback_user_id, content_or_opts})
    end
  end

  defp send_response(response) when is_tuple(response) do
    case response do
      {:message, channel_id, content_or_opts} ->
        result = Api.create_message(channel_id, content_or_opts)

        case result do
          {:error, _reason} -> {:error, @create_message_error}
          ok -> ok
        end

      {:dm, user_id, content_or_opts} ->
        send_dm(user_id, content_or_opts)
    end
  end

  defp generate_contextual_source(source, guild_id, channel_id) do
    if guild_id != nil do
      %{name: guild_name} = Api.get_guild!(guild_id)
      %{name: channel_name} = Api.get_channel!(channel_id)
      channel_name = "##{channel_name}"
      "#{code_inline(source)} in #{code_inline(channel_name)} in #{code_inline(guild_name)}"
    else
      "#{code_inline(source)} in #{code_inline("DM")}"
    end
  end

  defp send_dm(user_id, content_or_opts) when is_integer(user_id) do
    {:ok, %{id: channel_id}} = Api.create_dm(user_id)
    Api.create_message(channel_id, content_or_opts)
  end

  defp build_error_embed({:error, reason, source})
       when is_binary(reason) and is_binary(source),
       do: base_error_embed(reason, source)

  defp build_error_embed({:error, reason, source, stacktrace})
       when is_binary(reason) and is_list(stacktrace) do
    stacktrace = Exception.format_stacktrace(stacktrace)

    base_error_embed(reason, source)
    |> Embed.put_field("Stacktrace", code_block(stacktrace))
  end

  defp base_error_embed(reason, source)
       when is_binary(reason) and is_binary(source) do
    %Embed{}
    |> Embed.put_title("Error")
    |> Embed.put_color(@color_red)
    |> Embed.put_description(code_inline(reason))
    |> Embed.put_field("Source", source)
    |> Embed.put_timestamp(current_timestamp())
  end

  defp code_inline(content) when is_binary(content), do: "`#{content}`"

  defp code_block(content) when is_binary(content), do: "```#{content}```"

  defp current_timestamp do
    DateTime.utc_now()
    |> DateTime.to_string()
  end
end
