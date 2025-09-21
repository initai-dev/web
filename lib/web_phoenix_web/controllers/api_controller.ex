defmodule WebPhoenixWeb.ApiController do
  use WebPhoenixWeb, :controller

  @doc """
  Version check endpoint
  Returns current installer and API version information
  """
  def version(conn, _params) do
    case get_installer_manifest() do
      {:ok, manifest} ->
        conn
        |> json(%{
          status: "ok",
          current_version: manifest["version"],
          api_version: manifest["api"]["version"],
          release_date: manifest["release_date"],
          installers: manifest["installers"],
          api: manifest["api"],
          compatibility: manifest["compatibility"]
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          status: "error",
          error: "Failed to load version information",
          reason: to_string(reason)
        })
    end
  end

  @doc """
  Check for updates endpoint
  Compares client version with current version for specific script
  """
  def check_updates(conn, %{"client_version" => client_version} = params) do
    script = Map.get(params, "script", "bash")  # Default to bash if not specified

    case get_installer_manifest() do
      {:ok, manifest} ->
        # Get script-specific version or fallback to global version
        script_info = get_in(manifest, ["installers", script])
        current_version = if script_info, do: script_info["version"], else: manifest["version"]

        update_available = case compare_versions(client_version, current_version) do
          :lt -> true
          _ -> false
        end

        response = %{
          status: "ok",
          script: script,
          client_version: client_version,
          current_version: current_version,
          update_available: update_available
        }

        response = if update_available do
          Map.merge(response, %{
            changelog: get_changelog_since_version(manifest, client_version),
            script_info: script_info,
            download_url: if(script_info, do: script_info["url"], else: "/install.sh")
          })
        else
          response
        end

        conn |> json(response)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          status: "error",
          error: "Failed to check for updates",
          reason: to_string(reason)
        })
    end
  end

  @doc """
  Health check endpoint
  """
  def health(conn, _params) do
    conn
    |> json(%{
      status: "ok",
      service: "initai.dev",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: get_app_version()
    })
  end

  @doc """
  Get installer manifest
  """
  defp get_installer_manifest() do
    manifest_path = Path.join([Application.app_dir(:web_phoenix, "priv"), "static", "installer-manifest.json"])

    case File.read(manifest_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, manifest} -> {:ok, manifest}
          {:error, reason} -> {:error, reason}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Compare two semantic versions
  Returns :lt, :eq, or :gt
  """
  defp compare_versions(version1, version2) do
    v1_parts = parse_version(version1)
    v2_parts = parse_version(version2)

    case {v1_parts, v2_parts} do
      {{:ok, v1}, {:ok, v2}} -> compare_version_parts(v1, v2)
      _ -> :eq  # If we can't parse, assume equal
    end
  end

  defp parse_version(version) do
    try do
      parts = version
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)

      case parts do
        [major, minor, patch] -> {:ok, {major, minor, patch}}
        [major, minor] -> {:ok, {major, minor, 0}}
        [major] -> {:ok, {major, 0, 0}}
        _ -> {:error, :invalid_format}
      end
    rescue
      _ -> {:error, :invalid_format}
    end
  end

  defp compare_version_parts({maj1, min1, pat1}, {maj2, min2, pat2}) do
    cond do
      maj1 < maj2 -> :lt
      maj1 > maj2 -> :gt
      min1 < min2 -> :lt
      min1 > min2 -> :gt
      pat1 < pat2 -> :lt
      pat1 > pat2 -> :gt
      true -> :eq
    end
  end

  @doc """
  Get changelog entries since a specific version
  """
  defp get_changelog_since_version(manifest, since_version) do
    changelog = manifest["changelog"] || []

    changelog
    |> Enum.filter(fn entry ->
      entry_version = entry["version"]
      compare_versions(since_version, entry_version) == :lt
    end)
    |> Enum.sort_by(&(&1["version"]), :desc)
  end

  @doc """
  Get application version
  """
  defp get_app_version() do
    case Application.spec(:web_phoenix, :vsn) do
      nil -> "unknown"
      vsn -> List.to_string(vsn)
    end
  end
end