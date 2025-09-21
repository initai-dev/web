defmodule WebPhoenixWeb.Router do
  use WebPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {WebPhoenixWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebPhoenixWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/content", ContentController, :index
    get "/content/*path", ContentController, :show

    # Install script routes
    get "/install.sh", InstallController, :install_sh
    get "/install.ps1", InstallController, :install_ps1
    get "/install.py", InstallController, :install_py


    # New init endpoints (future-proof)
    get "/init/:tenant/list", InitController, :list_packages
    get "/init/:tenant/:framework", InitController, :download_package
    get "/init/:tenant/:framework/:llm", InitController, :download_package
  end

  # API routes
  scope "/api", WebPhoenixWeb do
    pipe_through :api

    get "/version", ApiController, :version
    get "/health", ApiController, :health
    get "/check-updates", ApiController, :check_updates
  end
end
