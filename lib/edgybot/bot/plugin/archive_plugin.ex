defmodule Edgybot.Bot.Plugin.Archive do
  @moduledoc false

  use Edgybot.Bot.Plugin

  alias Edgybot.Config

  @impl true
  def get_plugin_definitions do
    [
      %{
        application_command: %{
          name: "archive",
          description: "Archive pages with the internet archive",
          type: 1,
          options: [
            %{
              name: "url",
              description: "The URL to archive",
              type: 3,
              required: true
            },
            %{
              name: "query-params",
              description: "Whether or not to preserve the query params of the link when archiving",
              type: 5,
              required: false
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(["archive"], 1, [{"url", 3, url} | other_options], _interaction, _middleware_data) do
    preserve_query_params? = find_option_value(other_options, "query-params")

    parsed_url = URI.parse(url)

    preserve_query_params_host? =
      Enum.any?(Config.archive_hosts_preserve_query(), fn host -> host == parsed_url.host end)

    if_result =
      if preserve_query_params? || preserve_query_params_host? do
        parsed_url
      else
        %{parsed_url | query: nil}
      end

    prepared_url = URI.to_string(if_result)

    archived_url = "https://archive.today/latest/#{prepared_url}"

    {:message, "**Original link**: #{url}\n\n**Archived at**: <#{archived_url}>"}
  end
end
