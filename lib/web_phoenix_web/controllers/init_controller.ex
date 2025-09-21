defmodule WebPhoenixWeb.InitController do
  use WebPhoenixWeb, :controller

  @doc """
  Main endpoint for downloading initialization files as ZIP
  Pattern: /init/[tenant]/[framework]/[llm] or /init/[tenant]/[framework]
  For now we use "shared" as tenant, later this will be user-configurable
  LLM is optional - if not specified, returns universal framework files
  """
  def download_package(conn, %{"tenant" => tenant, "framework" => framework} = params) do
    llm = Map.get(params, "llm", "universal")
    download_package_impl(conn, tenant, framework, llm)
  end

  # Implementation function
  defp download_package_impl(conn, tenant, framework, llm) do
    case create_init_package(tenant, framework, llm) do
      {:ok, zip_data, manifest} ->
        filename = "#{framework}-#{llm}-init.zip"

        conn
        |> put_resp_content_type("application/zip")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, zip_data)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Package not found", tenant: tenant, framework: framework, llm: llm})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to create package", reason: to_string(reason)})
    end
  end

  @doc """
  Create ZIP package with all initialization files and manifest
  """
  defp create_init_package(tenant, framework, llm) do
    # For now, only support "shared" tenant
    if tenant != "shared" do
      {:error, :not_found}
    else
      case get_framework_files(framework, llm) do
        {:ok, files} ->
          manifest = create_manifest(framework, llm, files)

          case create_zip(files, manifest) do
            {:ok, zip_data} -> {:ok, zip_data, manifest}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Get all files for a specific framework and LLM
  Priority: specific LLM files > universal framework files
  """
  defp get_framework_files(framework, llm) do
    # Try specific LLM path first, then fallback to universal
    specific_path = Path.join(["priv", "static", "packages", "shared", framework, llm])
    universal_path = Path.join(["priv", "static", "packages", "shared", framework])

    content_path = cond do
      llm != "universal" && File.dir?(specific_path) -> specific_path  # LLM-specific exists
      File.dir?(universal_path) -> universal_path  # Use universal
      true -> specific_path  # Try specific anyway (will fail properly)
    end

    case File.ls(content_path) do
      {:ok, entries} ->
        files = entries
        |> Enum.filter(&(!String.ends_with?(&1, ".zip")))  # Exclude zip files
        |> Enum.filter(&(!File.dir?(Path.join([content_path, &1]))))  # Exclude directories
        |> Enum.map(fn filename ->
          file_path = Path.join([content_path, filename])
          case File.read(file_path) do
            {:ok, content} ->
              %{
                name: filename,
                content: content,
                path: filename
              }
            {:error, _} -> nil
          end
        end)
        |> Enum.filter(&(!is_nil(&1)))

        if length(files) > 0 do
          {:ok, files}
        else
          {:error, :no_files_found}
        end

      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Create manifest.json for the package
  """
  defp create_manifest(framework, llm, files) do
    %{
      version: "1.0.0",
      tenant: "shared",
      framework: framework,
      llm: llm,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      files: Enum.map(files, fn file ->
        %{
          name: file.name,
          path: file.path,
          size: byte_size(file.content)
        }
      end),
      metadata: %{
        description: get_framework_description(framework, llm),
        install_instructions: "Extract all files to your project's initialization directory"
      }
    }
  end

  @doc """
  Create ZIP file containing all files and manifest
  """
  defp create_zip(files, manifest) do
    try do
      # Create file list for ZIP creation - correct format
      manifest_content = Jason.encode!(manifest, pretty: true)

      zip_files = [
        # Add manifest.json - filename as charlist, content as binary
        {~c"manifest.json", manifest_content}
      ] ++
      # Add all framework files
      Enum.map(files, fn file ->
        # Filename as charlist, content as binary
        filename_charlist = String.to_charlist(file.path)
        content = if is_binary(file.content), do: file.content, else: to_string(file.content)
        {filename_charlist, content}
      end)

      # Create ZIP in memory
      case :zip.create(~c"init-package.zip", zip_files, [:memory]) do
        {:ok, {_filename, zip_data}} -> {:ok, zip_data}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  @doc """
  Get framework description - this will later come from database
  """
  defp get_framework_description(framework, llm) do
    case {framework, llm} do
      {"blissframework", "claude"} -> "Bliss Framework for Claude - Developer happiness and rapid iteration"
      {"blissframework", "gemini"} -> "Bliss Framework for Gemini - Streamlined development experience"
      {"blissframework", "universal"} -> "Bliss Framework - Universal developer happiness and rapid iteration"
      {_, _} -> "LLM initialization framework"
    end
  end

  @doc """
  List available packages for a tenant (future endpoint)
  Pattern: /init/[tenant]/list
  """
  def list_packages(conn, %{"tenant" => tenant}) do
    if tenant != "shared" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Tenant not found"})
    else
      packages = get_available_packages()

      conn
      |> json(%{
        tenant: tenant,
        packages: packages,
        total: length(packages)
      })
    end
  end

  @doc """
  Get list of available packages - this will later query database
  """
  defp get_available_packages do
    packages_dir = Path.join(["priv", "static", "packages", "shared"])

    case File.ls(packages_dir) do
      {:ok, frameworks} ->
        frameworks
        |> Enum.filter(&File.dir?(Path.join([packages_dir, &1])))
        |> Enum.flat_map(fn framework ->
          framework_path = Path.join([packages_dir, framework])

          # Check for universal package (framework root)
          universal_package = if File.exists?(Path.join([framework_path, "manifest.json"])) do
            [%{
              framework: framework,
              llm: "universal",
              description: get_framework_description(framework, "universal"),
              download_url: "/init/shared/#{framework}"
            }]
          else
            []
          end

          # Check for LLM-specific packages
          llm_packages = case File.ls(framework_path) do
            {:ok, entries} ->
              entries
              |> Enum.filter(&File.dir?(Path.join([framework_path, &1])))
              |> Enum.filter(&File.exists?(Path.join([framework_path, &1, "manifest.json"])))
              |> Enum.map(fn llm ->
                %{
                  framework: framework,
                  llm: llm,
                  description: get_framework_description(framework, llm),
                  download_url: "/init/shared/#{framework}/#{llm}"
                }
              end)
            _ -> []
          end

          universal_package ++ llm_packages
        end)
      _ -> []
    end
  end
end