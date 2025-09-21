defmodule WebPhoenixWeb.DocsHelpers do
  @moduledoc """
  Helper functions for documentation layout and navigation.
  """

  @doc """
  Determines if a section should be expanded based on the current request path.
  """
  def is_section_active?(section, current_path) do
    section[:items]
    |> Enum.any?(fn item ->
      case item[:type] do
        :subsection ->
          # Check if any subsection item matches
          String.starts_with?(current_path, item[:path] || "") ||
          Enum.any?(item[:items] || [], &String.starts_with?(current_path, &1[:path] || ""))
        _ ->
          # Check if regular item matches
          String.starts_with?(current_path, item[:path] || "")
      end
    end)
  end

  @doc """
  Determines if a specific path should be highlighted as active.
  Useful for framework sections that should be highlighted when any of their pages are active.
  """
  def is_path_active?(path, current_path) do
    String.starts_with?(current_path, path || "")
  end
end