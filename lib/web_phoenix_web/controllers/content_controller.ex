defmodule WebPhoenixWeb.ContentController do
  use WebPhoenixWeb, :controller

  def show(conn, %{"path" => path}) do
    # Handle both string and list paths
    normalized_path = case path do
      path when is_list(path) -> Enum.join(path, "/")
      path when is_binary(path) -> path
    end

    # Handle smart folder navigation
    resolved_path = resolve_smart_path(normalized_path)

    case WebPhoenix.Markdown.get_content(resolved_path) do
      {:ok, html} ->
        # Generate breadcrumbs based on path
        breadcrumbs = generate_breadcrumbs(normalized_path)

        conn
        |> put_layout({WebPhoenixWeb.LayoutView, :docs})
        |> assign(:breadcrumbs, breadcrumbs)
        |> assign(:content_list, WebPhoenix.Markdown.get_menu_structure())
        |> render("show.html", content: html, title: format_title(normalized_path))
      {:error, message} ->
        # Generate suggestions for similar content
        suggested_pages = generate_suggestions(normalized_path)
        breadcrumbs = generate_breadcrumbs(normalized_path)

        conn
        |> put_layout({WebPhoenixWeb.LayoutView, :docs})
        |> put_status(:not_found)
        |> assign(:breadcrumbs, breadcrumbs)
        |> assign(:content_list, WebPhoenix.Markdown.get_menu_structure())
        |> assign(:suggested_pages, suggested_pages)
        |> render("not_found.html", message: message)
    end
  end

  def index(conn, _params) do
    content_list = WebPhoenix.Markdown.get_menu_structure()

    conn
    |> put_layout({WebPhoenixWeb.LayoutView, :docs})
    |> assign(:breadcrumbs, [{"Home", "/"}, {"Documentation", ""}])
    |> assign(:content_list, content_list)
    |> render("index.html", content_list: content_list)
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

  defp generate_breadcrumbs(path) do
    parts = String.split(path, "/", trim: true)
    base_crumbs = [{"Home", "/"}, {"Documentation", "/content"}]

    path_crumbs = parts
    |> Enum.with_index()
    |> Enum.map(fn {part, index} ->
      if index == length(parts) - 1 do
        # Last part - no link
        {format_title(part), ""}
      else
        # Build URL up to this part
        partial_path = parts |> Enum.take(index + 1) |> Enum.join("/")
        {format_title(part), "/content/#{partial_path}"}
      end
    end)

    base_crumbs ++ path_crumbs
  end

  defp generate_suggestions(requested_path) do
    path_parts = String.split(requested_path, "/", trim: true)

    suggestions = case path_parts do
      # If it's a framework-specific page that doesn't exist
      [llm, framework | _] when llm in ["claude", "gemini"] ->
        get_framework_suggestions(llm, framework)

      # If it's an LLM-specific page
      [llm | _] when llm in ["claude", "gemini"] ->
        get_llm_suggestions(llm)

      # General suggestions for other missing pages
      _ ->
        get_general_suggestions()
    end

    # Limit to 5 suggestions
    Enum.take(suggestions, 5)
  end

  defp get_framework_suggestions(llm, framework) do
    # Get available pages for this framework
    framework_files = WebPhoenix.Markdown.list_framework_content(llm, framework)

    framework_suggestions = Enum.map(framework_files, fn file ->
      %{
        title: format_title(file),
        path: "/content/#{llm}/#{framework}/#{file}",
        icon: "fas fa-file-alt",
        description: "#{String.capitalize(framework)} guide"
      }
    end)

    # Add installation page as fallback
    installation_suggestion = %{
      title: "#{String.capitalize(llm)} Installation",
      path: "/content/#{llm}/installation",
      icon: "fas fa-download",
      description: "Get started with #{String.capitalize(llm)}"
    }

    [installation_suggestion | framework_suggestions]
  end

  defp get_llm_suggestions(llm) do
    llm_files = WebPhoenix.Markdown.list_llm_files(llm)

    Enum.map(llm_files, fn file ->
      %{
        title: format_title(file),
        path: "/content/#{llm}/#{file}",
        icon: get_file_icon(file),
        description: "#{String.capitalize(llm)} documentation"
      }
    end)
  end

  defp get_general_suggestions do
    [
      %{
        title: "How It Works",
        path: "/content/how-it-works",
        icon: "fas fa-info-circle",
        description: "Learn how our initialization scripts work"
      },
      %{
        title: "Getting Started",
        path: "/content/getting-started",
        icon: "fas fa-play",
        description: "Quick start guide"
      },
      %{
        title: "Claude Installation",
        path: "/content/claude/installation",
        icon: "fas fa-download",
        description: "Install and configure Claude"
      },
      %{
        title: "Gemini Installation",
        path: "/content/gemini/installation",
        icon: "fas fa-download",
        description: "Install and configure Gemini"
      }
    ]
  end

  defp get_file_icon(filename) do
    case filename do
      "installation" -> "fas fa-download"
      "getting-started" -> "fas fa-play"
      "configuration" -> "fas fa-cogs"
      _ -> "fas fa-file-alt"
    end
  end

  # Resolve smart folder navigation paths
  defp resolve_smart_path(path) do
    path_parts = String.split(path, "/", trim: true)

    case path_parts do
      # Handle LLM/framework paths (e.g., "claude/blissframework")
      [llm, framework] ->
        case WebPhoenix.Markdown.get_framework_default_content(llm, framework) do
          nil -> path  # No content found, keep original path
          default_content -> "#{llm}/#{framework}/#{default_content}"
        end

      # Handle LLM/framework/sublanguage paths (e.g., "claude/blissframework/csharp")
      [llm, framework, sublanguage] ->
        case WebPhoenix.Markdown.get_framework_default_content(llm, "#{framework}/#{sublanguage}") do
          nil -> path  # No content found, keep original path
          default_content -> "#{llm}/#{framework}/#{sublanguage}/#{default_content}"
        end

      # For other paths, return as is
      _ -> path
    end
  end
end