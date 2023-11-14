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
    internet_archive_url = "https://web.archive.org/save/#{url}"

    response_tuple =
      :get
      |> Finch.build(internet_archive_url)
      |> Finch.request(FinchPool, receive_timeout: 840_000)

    case response_tuple do
      {:ok, response} ->
        location_header = List.keyfind(response.headers, "location", 0)

        case location_header do
          {_, archived_url} ->
            {:message, "**Original link**: #{url}\n\n**Archived at**: <#{archived_url}>"}

          _ ->
            {:error,
             "The Internet Archive could not archive that page! It may not be supported for archiving."}
        end

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:warning,
         "The Internet Archive did not respond in time. Some articles may take a while to archive for the first time. Please try again in the future."}
    end
  end
end
