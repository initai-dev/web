defmodule WebPhoenix.Markdown do
  @moduledoc """
  Module for handling Markdown content rendering and file management.
  """

  @content_dir "priv/content"

  @doc """
  Sanitizes a path to prevent directory traversal attacks.
  Only allows alphanumeric characters, hyphens, underscores, and forward slashes.
  Blocks any path containing '..' or starting with '/'.
  """
  def sanitize_path(path) when is_binary(path) do
    cond do
      String.contains?(path, "..") -> {:error, "Path traversal not allowed"}
      String.starts_with?(path, "/") -> {:error, "Absolute paths not allowed"}
      String.contains?(path, "\\") -> {:error, "Backslashes not allowed"}
      not Regex.match?(~r/^[a-zA-Z0-9\/_-]+$/, path) -> {:error, "Invalid characters in path"}
      true -> {:ok, path}
    end
  end

  def render(markdown_text) when is_binary(markdown_text) do
    case Earmark.as_html(markdown_text) do
      {:ok, html, _} -> {:ok, html}
      {:error, _, errors} -> {:error, errors}
    end
  end

  def get_content(path) do
    case sanitize_path(path) do
      {:ok, safe_path} ->
        file_path = Path.join([@content_dir, "#{safe_path}.md"])

        # Additional security: ensure the resolved path is still within content directory
        abs_content_dir = Path.expand(@content_dir)
        abs_file_path = Path.expand(file_path)

        if String.starts_with?(abs_file_path, abs_content_dir) do
          case File.read(file_path) do
            {:ok, content} ->
              case render(content) do
                {:ok, html} -> {:ok, html}
                {:error, errors} -> {:error, "Markdown parsing error: #{inspect(errors)}"}
              end
            {:error, :enoent} -> {:error, "Content not found: #{path}"}
            {:error, reason} -> {:error, "File error: #{reason}"}
          end
        else
          {:error, "Path outside content directory not allowed"}
        end
      {:error, message} -> {:error, message}
    end
  end

  def list_content() do
    content_path = @content_dir

    case File.ls(content_path) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace_suffix(&1, ".md", ""))
        |> Enum.sort()
      {:error, _} -> []
    end
  end

  def list_framework_content(llm, framework) do
    framework_path = Path.join([@content_dir, llm, framework])

    case File.ls(framework_path) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace_suffix(&1, ".md", ""))
        |> Enum.reject(&(&1 == "index"))  # Exclude index.md from submenu items
        |> Enum.sort()
      {:error, _} -> []
    end
  end

  # Check if a framework folder has index.md
  def has_framework_index?(llm, framework) do
    index_path = Path.join([@content_dir, llm, framework, "index.md"])
    File.exists?(index_path)
  end

  # Get the default content for a framework (index.md if exists, otherwise first file)
  def get_framework_default_content(llm, framework) do
    if has_framework_index?(llm, framework) do
      "index"
    else
      # Get first available file (excluding index.md)
      framework_path = Path.join([@content_dir, llm, framework])
      case File.ls(framework_path) do
        {:ok, files} ->
          files
          |> Enum.filter(&String.ends_with?(&1, ".md"))
          |> Enum.map(&String.replace_suffix(&1, ".md", ""))
          |> Enum.reject(&(&1 == "index"))
          |> Enum.sort()
          |> List.first()
        {:error, _} -> nil
      end
    end
  end

  def list_llms() do
    case File.ls(@content_dir) do
      {:ok, entries} ->
        entries
        |> Enum.filter(fn entry ->
          path = Path.join(@content_dir, entry)
          File.dir?(path)
        end)
        |> Enum.sort()
      {:error, _} -> []
    end
  end

  def list_frameworks(llm) do
    llm_path = Path.join(@content_dir, llm)

    case File.ls(llm_path) do
      {:ok, entries} ->
        entries
        |> Enum.filter(fn entry ->
          path = Path.join(llm_path, entry)
          File.dir?(path)
        end)
        |> Enum.sort()
      {:error, _} -> []
    end
  end

  def get_menu_structure() do
    menu_config = Application.get_env(:web_phoenix, :menu_config)

    # Start with fixed items
    fixed_sections = menu_config[:fixed_items] || []

    # Generate dynamic LLM provider sections
    llm_sections = generate_llm_sections(menu_config)

    # Combine all sections
    fixed_sections ++ llm_sections
  end

  defp generate_llm_sections(menu_config) do
    llm_providers = menu_config[:llm_providers] || []
    framework_config = menu_config[:frameworks] || %{}

    Enum.map(llm_providers, fn provider ->
      llm_name = provider.name

      # Check if this LLM actually exists in filesystem
      if File.dir?(Path.join([@content_dir, llm_name])) do
        # Get actual frameworks from filesystem
        actual_frameworks = list_frameworks(llm_name)

        # Get LLM-level files (like installation.md)
        llm_files = list_llm_files(llm_name)

        # Create framework subsections
        framework_items = actual_frameworks
        |> Enum.filter(&(&1 in provider.frameworks))  # Only show configured frameworks
        |> Enum.sort_by(&(get_in(framework_config, [&1, :priority]) || 999))
        |> Enum.map(fn framework ->
          framework_meta = framework_config[framework] || %{}

          # Get both files and subdirectories
          {content_files, subdirectories} = get_framework_structure(llm_name, framework)

          # Create items for direct files
          file_items = Enum.map(content_files, fn file ->
            %{
              title: format_title(file),
              path: "/content/#{llm_name}/#{framework}/#{file}",
              icon: "fas fa-file-alt"
            }
          end)

          # Create items for subdirectories (third level)
          subdir_items = Enum.map(subdirectories, fn subdir ->
            subdir_files = list_framework_content(llm_name, "#{framework}/#{subdir}")

            # Read manifest for subdirectory
            subdir_path = Path.join([@content_dir, llm_name, framework, subdir])
            subdir_manifest = read_manifest(subdir_path)
            subdir_icon_class = generate_icon_class(subdir_manifest)
            subdir_color = get_icon_color(subdir_manifest)

            subdir_file_items = Enum.map(subdir_files, fn file ->
              %{
                title: format_title(file),
                path: "/content/#{llm_name}/#{framework}/#{subdir}/#{file}",
                icon: "fas fa-file-alt"
              }
            end)

            %{
              type: :subsection,
              title: get_in(subdir_manifest, ["metadata", "title"]) || format_title(subdir),
              path: "/content/#{llm_name}/#{framework}/#{subdir}",
              icon: subdir_icon_class,
              color: subdir_color,
              items: subdir_file_items
            }
          end)

          # Combine file items and subdirectory items
          all_items = file_items ++ subdir_items

          %{
            type: :subsection,
            title: framework_meta[:title] || String.capitalize(framework),
            icon: framework_meta[:icon] || "fas fa-cog",
            path: "/content/#{llm_name}/#{framework}",
            items: all_items
          }
        end)

        # Create LLM-level items (like installation)
        llm_items = Enum.map(llm_files, fn file ->
          %{
            title: format_title(file),
            path: "/content/#{llm_name}/#{file}",
            icon: get_file_icon(file)
          }
        end)

        %{
          type: :section,
          title: provider.title,
          icon: provider.icon,
          description: provider.description,
          items: llm_items ++ framework_items
        }
      else
        nil
      end
    end)
    |> Enum.filter(&(!is_nil(&1)))  # Remove non-existent LLMs
  end

  defp get_file_icon(filename) do
    case filename do
      "installation" -> "fas fa-download"
      "getting-started" -> "fas fa-play"
      "configuration" -> "fas fa-cogs"
      _ -> "fas fa-file-alt"
    end
  end

  # Get both files and subdirectories for a framework
  def get_framework_structure(llm, framework) do
    framework_path = Path.join([@content_dir, llm, framework])

    case File.ls(framework_path) do
      {:ok, entries} ->
        # Separate files and directories
        {files, directories} = Enum.split_with(entries, fn entry ->
          path = Path.join(framework_path, entry)
          !File.dir?(path)
        end)

        # Process files (remove .md extension and exclude index.md)
        content_files = files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace_suffix(&1, ".md", ""))
        |> Enum.reject(&(&1 == "index"))
        |> Enum.sort()

        # Return directories as-is, sorted
        subdirectories = directories |> Enum.sort()

        {content_files, subdirectories}

      {:error, _} -> {[], []}
    end
  end

  defp format_title(text) do
    text
    |> String.replace("-", " ")
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def list_llm_files(llm) do
    llm_path = Path.join(@content_dir, llm)

    case File.ls(llm_path) do
      {:ok, entries} ->
        entries
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace_suffix(&1, ".md", ""))
        |> Enum.sort()
      {:error, _} -> []
    end
  end

  def content_exists?(path) do
    file_path = Path.join([@content_dir, "#{path}.md"])
    File.exists?(file_path)
  end

  @doc """
  Read and parse manifest.toml file for a specific folder
  Returns manifest data or default values if file doesn't exist
  """
  def read_manifest(folder_path) do
    manifest_path = Path.join([folder_path, "manifest.toml"])

    case File.read(manifest_path) do
      {:ok, content} ->
        # Simple TOML parser for our specific manifest structure
        parse_simple_toml(content)
      {:error, _} -> default_manifest()
    end
  end

  defp parse_simple_toml(content) do
    lines = String.split(content, "\n")

    lines
    |> Enum.reduce({%{}, nil}, fn line, {acc, current_section} ->
      line = String.trim(line)

      cond do
        # Section headers like [icon]
        String.starts_with?(line, "[") and String.ends_with?(line, "]") ->
          section = String.slice(line, 1..-2//1)
          {Map.put(acc, section, %{}), section}

        # Key-value pairs like source = "devicon"
        String.contains?(line, "=") and current_section != nil ->
          [key, value] = String.split(line, "=", parts: 2)
          key = String.trim(key)
          value = String.trim(value) |> String.trim("\"")
          section_data = Map.get(acc, current_section, %{})
          updated_section = Map.put(section_data, key, value)
          {Map.put(acc, current_section, updated_section), current_section}

        # Empty lines or comments
        true ->
          {acc, current_section}
      end
    end)
    |> elem(0)
  end

  defp default_manifest do
    %{
      "icon" => %{
        "source" => "fontawesome",
        "name" => "fas fa-folder",
        "color" => "#6c757d"
      },
      "metadata" => %{
        "title" => "Folder",
        "description" => "",
        "priority" => 999
      }
    }
  end

  @doc """
  Generate icon class string based on manifest data
  """
  def generate_icon_class(manifest) do
    icon_config = manifest["icon"] || %{}
    source = icon_config["source"] || "fontawesome"
    name = icon_config["name"] || "fas fa-folder"

    case source do
      "devicon" ->
        variant = icon_config["variant"] || "plain"
        "devicon-#{name}-#{variant} colored"
      "fontawesome" -> name
      "svg" -> "custom-svg-icon"  # For custom SVG handling
      _ -> "fas fa-folder"  # fallback
    end
  end

  @doc """
  Get icon color from manifest
  """
  def get_icon_color(manifest) do
    get_in(manifest, ["icon", "color"]) || "#6c757d"
  end
end