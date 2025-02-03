defmodule EdgybotWeb.Router do
  use EdgybotWeb, :router
  use ErrorTracker.Web, :router

  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EdgybotWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  scope "/", EdgybotWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: EdgybotWeb.Telemetry
    oban_dashboard("/oban")
    error_tracker_dashboard("/errors")
  end

  # Other scopes may use custom stacks.
  # scope "/api", EdgybotWeb do
  #   pipe_through :api
  # end

  defp admin_basic_auth(conn, _opts) do
    if Application.get_env(:edgybot, :web_admin_auth_enabled, true) do
      username = System.fetch_env!("ADMIN_USERNAME")
      password = System.fetch_env!("ADMIN_PASSWORD")
      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    else
      conn
    end
  end
end
