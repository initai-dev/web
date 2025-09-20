defmodule WebPhoenix.Markdown do
  @moduledoc """
  Module for handling Markdown content rendering and file management.
  """

  @content_dir "priv/content"

  def render(markdown_text) when is_binary(markdown_text) do
    case Earmark.as_html(markdown_text) do
      {:ok, html, _} -> {:ok, html}
      {:error, _, errors} -> {:error, errors}
    end
  end

  def get_content(path) do
    file_path = Path.join([@content_dir, "#{path}.md"])

    case File.read(file_path) do
      {:ok, content} ->
        case render(content) do
          {:ok, html} -> {:ok, html}
          {:error, errors} -> {:error, "Markdown parsing error: #{inspect(errors)}"}
        end
      {:error, :enoent} -> {:error, "Content not found: #{path}"}
      {:error, reason} -> {:error, "File error: #{reason}"}
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
        |> Enum.sort()
      {:error, _} -> []
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
    llms = list_llms()

    Enum.map(llms, fn llm ->
      frameworks = list_frameworks(llm)
      llm_files = list_llm_files(llm)

      framework_data = Enum.map(frameworks, fn framework ->
        content = list_framework_content(llm, framework)
        %{name: framework, content: content}
      end)

      %{name: llm, frameworks: framework_data, files: llm_files}
    end)
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
end