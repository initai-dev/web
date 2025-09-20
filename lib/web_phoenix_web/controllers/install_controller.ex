defmodule WebPhoenixWeb.InstallController do
  use WebPhoenixWeb, :controller

  def install_sh(conn, _params) do
    static_path = Path.join([Application.app_dir(:web_phoenix, "priv"), "static", "install.sh"])

    case File.read(static_path) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)
      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> send_resp(404, "Script not found")
    end
  end

  def install_ps1(conn, _params) do
    static_path = Path.join([Application.app_dir(:web_phoenix, "priv"), "static", "install.ps1"])

    case File.read(static_path) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)
      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> send_resp(404, "Script not found")
    end
  end

  def install_py(conn, _params) do
    static_path = Path.join([Application.app_dir(:web_phoenix, "priv"), "static", "install.py"])

    case File.read(static_path) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)
      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> send_resp(404, "Script not found")
    end
  end

  def manifest(conn, _params) do
    static_path = Path.join([Application.app_dir(:web_phoenix, "priv"), "static", "manifest.json"])

    case File.read(static_path) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, content)
      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> send_resp(404, "Manifest not found")
    end
  end

  def framework_file(conn, %{"llm" => llm, "framework" => framework, "file" => file}) do
    static_path = Path.join([
      Application.app_dir(:web_phoenix, "priv"),
      "static",
      llm,
      framework,
      file
    ])

    case File.read(static_path) do
      {:ok, content} ->
        content_type = case Path.extname(file) do
          ".json" -> "application/json"
          ".txt" -> "text/plain"
          ".yaml" -> "text/yaml"
          ".yml" -> "text/yaml"
          _ -> "text/plain"
        end

        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, content)
      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> send_resp(404, "File not found")
    end
  end
end