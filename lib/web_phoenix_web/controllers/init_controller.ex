defmodule WebPhoenixWeb.InitController do
  use WebPhoenixWeb, :controller

  @doc """
  Main endpoint for downloading initialization files as ZIP
  Pattern: /init/[tenant]/[framework]/[scope]/[llm] or /init/[tenant]/[framework]/[scope]
  For now we use "shared" as tenant, later this will be user-configurable
  LLM is optional - if not specified, returns universal framework files
  """
  def download_package(conn, %{"tenant" => tenant, "framework" => framework, "scope" => scope} = params) do
    llm = Map.get(params, "llm", "universal")
    download_package_impl(conn, tenant, framework, scope, llm)
  end

  # Implementation function
  defp download_package_impl(conn, tenant, framework, scope, llm) do
    case create_init_package(tenant, framework, scope, llm) do
      {:ok, zip_data, manifest} ->
        filename = "#{framework}-#{scope}-#{llm}-init.zip"

        conn
        |> put_resp_content_type("application/zip")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, zip_data)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Package not found", tenant: tenant, framework: framework, scope: scope, llm: llm})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to create package", reason: to_string(reason)})
    end
  end

  @doc """
  Create ZIP package with all initialization files and manifest
  """
  defp create_init_package(tenant, framework, scope, llm) do
    # For now, only support "shared" tenant
    if tenant != "shared" do
      {:error, :not_found}
    else
      case get_framework_files(framework, scope, llm) do
        {:ok, files} ->
          manifest = create_manifest(framework, scope, llm, files)

          case create_zip(files, manifest) do
            {:ok, zip_data} -> {:ok, zip_data, manifest}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Get all files for a specific framework, scope and LLM
  Priority: specific LLM files > universal scope files
  """
  defp get_framework_files(framework, scope, llm) do
    # Try specific LLM path first, then fallback to universal
    specific_path = Path.join(["priv", "packages", "shared", framework, scope, llm])
    universal_path = Path.join(["priv", "packages", "shared", framework, scope])

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
  defp create_manifest(framework, scope, llm, files) do
    %{
      version: "1.0.0",
      tenant: "shared",
      framework: framework,
      scope: scope,
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
        description: get_framework_description(framework, scope, llm),
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
  defp get_framework_description(framework, scope, llm) do
    case {framework, scope, llm} do
      {"blissframework", "backend", "claude"} -> "Bliss Framework Backend for Claude - Server-side development with Claude optimizations"
      {"blissframework", "backend", "gemini"} -> "Bliss Framework Backend for Gemini - Server-side development with Gemini optimizations"
      {"blissframework", "backend", "universal"} -> "Bliss Framework Backend - Universal server-side development setup"
      {"blissframework", "frontend", "claude"} -> "Bliss Framework Frontend for Claude - Client-side development with Claude optimizations"
      {"blissframework", "frontend", "gemini"} -> "Bliss Framework Frontend for Gemini - Client-side development with Gemini optimizations"
      {"blissframework", "frontend", "universal"} -> "Bliss Framework Frontend - Universal client-side development setup"
      {"blissframework", "fullstack", "claude"} -> "Bliss Framework Fullstack for Claude - Complete application with Claude optimizations"
      {"blissframework", "fullstack", "gemini"} -> "Bliss Framework Fullstack for Gemini - Complete application with Gemini optimizations"
      {"blissframework", "fullstack", "universal"} -> "Bliss Framework Fullstack - Universal complete application setup"
      {_, _, _} -> "LLM initialization framework"
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
      frameworks = get_available_frameworks()

      conn
      |> json(%{
        tenant: tenant,
        frameworks: frameworks,
        total: length(frameworks)
      })
    end
  end

  @doc """
  Get list of available frameworks with their scopes and variants - this will later query database
  """
  defp get_available_frameworks do
    packages_dir = Path.join(["priv", "packages", "shared"])

    case File.ls(packages_dir) do
      {:ok, framework_names} ->
        framework_names
        |> Enum.filter(&File.dir?(Path.join([packages_dir, &1])))
        |> Enum.map(fn framework_name ->
          framework_path = Path.join([packages_dir, framework_name])

          # Get all scopes for this framework
          scopes = case File.ls(framework_path) do
            {:ok, scope_entries} ->
              scope_entries
              |> Enum.filter(&File.dir?(Path.join([framework_path, &1])))
              |> Enum.map(fn scope_name ->
                scope_path = Path.join([framework_path, scope_name])

                # Check for universal variant (scope root)
                universal_variants = if File.exists?(Path.join([scope_path, "manifest.json"])) do
                  [%{
                    type: "llm",
                    name: "universal",
                    description: "Works with any LLM",
                    download_url: "/init/shared/#{framework_name}/#{scope_name}"
                  }]
                else
                  []
                end

                # Check for LLM-specific variants
                llm_variants = case File.ls(scope_path) do
                  {:ok, llm_entries} ->
                    llm_entries
                    |> Enum.filter(&File.dir?(Path.join([scope_path, &1])))
                    |> Enum.filter(&File.exists?(Path.join([scope_path, &1, "manifest.json"])))
                    |> Enum.map(fn llm_name ->
                      %{
                        type: "llm",
                        name: llm_name,
                        description: get_llm_description(llm_name),
                        download_url: "/init/shared/#{framework_name}/#{scope_name}/#{llm_name}"
                      }
                    end)
                  _ -> []
                end

                all_variants = universal_variants ++ llm_variants

                %{
                  name: scope_name,
                  description: get_scope_description(scope_name),
                  variants: all_variants
                }
              end)
              |> Enum.filter(fn scope -> length(scope.variants) > 0 end)
            _ -> []
          end

          %{
            name: framework_name,
            description: get_base_framework_description(framework_name),
            scopes: scopes
          }
        end)
        |> Enum.filter(fn framework -> length(framework.scopes) > 0 end)
      _ -> []
    end
  end


  @doc """
  Get base framework description (without LLM-specific text)
  """
  defp get_base_framework_description(framework) do
    case framework do
      "blissframework" -> "Bliss Framework - Developer happiness and rapid iteration"
      _ -> "LLM initialization framework"
    end
  end

  @doc """
  Get scope-specific description
  """
  defp get_scope_description(scope) do
    case scope do
      "backend" -> "Server-side development and APIs"
      "frontend" -> "Client-side user interface development"
      "fullstack" -> "Complete application with frontend and backend"
      "api" -> "RESTful API development"
      "mobile" -> "Mobile application development"
      "desktop" -> "Desktop application development"
      _ -> "#{String.capitalize(scope)} development"
    end
  end

  @doc """
  Get LLM-specific description
  """
  defp get_llm_description(llm) do
    case llm do
      "claude" -> "Optimized for Claude AI"
      "gemini" -> "Optimized for Google Gemini"
      "universal" -> "Works with any LLM"
      _ -> "#{String.capitalize(llm)} integration"
    end
  end
end