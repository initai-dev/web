defmodule WebPhoenixWeb.PageController do
  use WebPhoenixWeb, :controller

  def index(conn, _params) do
    conn
    |> assign(:body_class, "homepage")
    |> render("index.html")
  end

end
