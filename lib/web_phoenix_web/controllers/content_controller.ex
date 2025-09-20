defmodule WebPhoenixWeb.ContentController do
  use WebPhoenixWeb, :controller

  def show(conn, %{"path" => path}) do
    # Handle both string and list paths
    normalized_path = case path do
      path when is_list(path) -> Enum.join(path, "/")
      path when is_binary(path) -> path
    end

    case WebPhoenix.Markdown.get_content(normalized_path) do
      {:ok, html} ->
        render(conn, "show.html", content: html, title: format_title(normalized_path))
      {:error, message} ->
        conn
        |> put_status(:not_found)
        |> render("not_found.html", message: message)
    end
  end

  def index(conn, _params) do
    content_list = WebPhoenix.Markdown.list_content()
    render(conn, "index.html", content_list: content_list)
  end

  # New handlers for /[llm]/[framework]/[content] structure
  def framework_show(conn, %{"llm" => llm, "framework" => framework, "path" => path}) do
    # Handle both string and list paths
    normalized_path = case path do
      path when is_list(path) -> Enum.join(path, "/")
      path when is_binary(path) -> path
    end

    full_path = "#{llm}/#{framework}/#{normalized_path}"

    case WebPhoenix.Markdown.get_content(full_path) do
      {:ok, html} ->
        conn
        |> put_layout({WebPhoenixWeb.LayoutView, :content})
        |> assign(:current_llm, llm)
        |> assign(:current_framework, framework)
        |> assign(:content_list, WebPhoenix.Markdown.list_framework_content(llm, framework))
        |> render("framework_show.html", content: html, title: format_title(normalized_path), llm: llm, framework: framework)
      {:error, message} ->
        conn
        |> put_layout({WebPhoenixWeb.LayoutView, :content})
        |> put_status(:not_found)
        |> render("not_found.html", message: message)
    end
  end

  def framework_index(conn, %{"llm" => llm, "framework" => framework}) do
    content_list = WebPhoenix.Markdown.list_framework_content(llm, framework)

    conn
    |> put_layout({WebPhoenixWeb.LayoutView, :content})
    |> assign(:current_llm, llm)
    |> assign(:current_framework, framework)
    |> assign(:content_list, content_list)
    |> render("framework_index.html", content_list: content_list, llm: llm, framework: framework)
  end

  def llm_show(conn, %{"llm" => llm, "file" => file}) do
    # Check if it's actually a framework directory
    frameworks = WebPhoenix.Markdown.list_frameworks(llm)
    if file in frameworks do
      # Redirect to framework index
      redirect(conn, to: "/#{llm}/#{file}")
    else
      # Handle as LLM file
      full_path = "#{llm}/#{file}"

      case WebPhoenix.Markdown.get_content(full_path) do
        {:ok, html} ->
          conn
          |> put_layout({WebPhoenixWeb.LayoutView, :content})
          |> assign(:current_llm, llm)
          |> assign(:current_file, file)
          |> render("llm_show.html", content: html, title: format_title(file), llm: llm, file: file)
        {:error, message} ->
          conn
          |> put_layout({WebPhoenixWeb.LayoutView, :content})
          |> put_status(:not_found)
          |> render("not_found.html", message: message)
      end
    end
  end

  defp format_title(path) do
    path
    |> String.split("/")
    |> List.last()
    |> String.replace("-", " ")
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end