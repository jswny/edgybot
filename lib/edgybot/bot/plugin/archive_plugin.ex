defmodule Edgybot.Bot.Plugin.Archive do
  @moduledoc false

  use Edgybot.Bot.Plugin

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
            }
          ]
        }
      }
    ]
  end

  @impl true
  def handle_interaction(
        ["archive"],
        1,
        [{"url", 3, url}],
        _interaction,
        _middleware_data
      ) do
    archived_url = "https://archive.today/latest/#{url}"

    {:message, "**Original link**: #{url}\n\n**Archived at**: <#{archived_url}>"}
  end
end
