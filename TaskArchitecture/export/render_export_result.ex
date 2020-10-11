defmodule TaskArchitecture.Services.Export.RenderExportResult do
  @moduledoc """
  Perform fetching the job offers and saving them into file storage.
  """

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.{Company, Export}
  alias TaskArchitecture.Services.Export.StorageClient

  import XmlBuilder

  @replace_text "098j23c"

  @spec get_exports_of_type(binary) :: {:ok, list(Export.t())} | {:error, binary}
  def get_exports_of_type(export_type) do
    with true <- ExportTargetType.valid_value?(export_type),
         exports when is_list(exports) and exports != [] <-
           Exports.list_active_exports(export_type, [:companies, :export_companies]) do
      {:ok, exports}
    else
      false ->
        {:error, "Invalid export type #{export_type}"}

      [] ->
        {:error, "No active exports"}
    end
  end

  @spec perform(binary) :: :ok | {:error, binary}
  def perform(export_type) do
    with {:ok, exports} <- get_exports_of_type(export_type),
         content <- read_files_for_exports(exports),
         result_file_content <- generate_file(content),
         {:ok, _} <- StorageClient.write_main_file_to_storage(result_file_content, export_type) do
      :ok
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec read_files_for_exports(list(Export.t())) :: binary
  defp read_files_for_exports(exports) do
    exports
    |> Enum.map(fn %Export{companies: companies} = export ->
      companies
      |> Enum.map(fn %Company{organization_reference: organization_reference} ->
        get_file_from_storage(organization_reference, export)
      end)
      |> Enum.filter(fn result -> not is_nil(result) end)
    end)
    |> Enum.filter(fn result -> result != [] end)
    |> List.flatten()
    |> Enum.join("\n")
  end

  @spec generate_file(binary) :: binary
  defp generate_file(content) do
    element(:liste, %{}, "\n    #{@replace_text}\n")
    |> document()
    |> generate()
    |> String.replace(@replace_text, content)
  end

  defp get_file_from_storage(organization_reference, export) do
    StorageClient.read_from_storage(organization_reference, export)
    |> case do
      {:ok, content} ->
        content

      {:error, _} ->
        nil
    end
  end
end
