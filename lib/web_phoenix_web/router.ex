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

    # New content structure: /[llm]/[framework]/[content]
    get "/:llm/:framework", ContentController, :framework_index
    get "/:llm/:framework/*path", ContentController, :framework_show

    # LLM direct files: /[llm]/[file]
    get "/:llm/:file", ContentController, :llm_show

    # Install script routes
    get "/install.sh", InstallController, :install_sh
    get "/install.ps1", InstallController, :install_ps1
    get "/install.py", InstallController, :install_py

    # API routes
    get "/manifest.json", InstallController, :manifest

    # Framework file routes
    get "/:llm/:framework/:file", InstallController, :framework_file
  end

  # Other scopes may use custom stacks.
  # scope "/api", WebPhoenixWeb do
  #   pipe_through :api
  # end
end
