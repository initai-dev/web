defmodule WebPhoenixWeb.PageController do
  use WebPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
