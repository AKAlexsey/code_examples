defmodule TaskArchitecture.Services.Export.StorageClient.DevStorage do
  @moduledoc """
  Represent interface or reading and writing file for development and testing environment
  """

  @behaviour TaskArchitecture.Services.Export.StorageClientBehaviour

  alias TaskArchitecture.Exports.Export

  if Mix.env() == :dev do
    @file_folder "feed_files"
  else
    @file_folder "test/feed_files"
  end

  def file_folder, do: @file_folder

  @spec write_to_storage(binary, binary, Export.t()) :: {:ok, binary} | {:error, any}
  def write_to_storage(file_content, organization_reference, export) do
    file_path = "#{get_folder_path(export)}#{get_file_name(organization_reference)}"

    case File.write(file_path, file_content) do
      {:error, :enoent} ->
        File.mkdir(@file_folder)
        File.mkdir(get_folder_path(export))

        File.write(file_path, file_content)

      other_response ->
        other_response
    end
    |> resolve_result()
  end

  @spec read_from_storage(binary, Export.t()) :: {:ok, binary} | {:error, any}
  def read_from_storage(organization_reference, %Export{} = export) do
    file_path = "#{get_folder_path(export)}#{get_file_name(organization_reference)}"

    File.read(file_path)
    |> resolve_result()
  end

  @spec delete_from_storage(binary, Export.t()) :: {:ok, binary} | {:error, any}
  def delete_from_storage(organization_reference, export) do
    file_path = "#{get_folder_path(export)}#{get_file_name(organization_reference)}"

    File.rm(file_path)
    |> resolve_result()
  end

  @spec write_main_file_to_storage(binary, binary) :: {:ok, binary} | {:error, any}
  def write_main_file_to_storage(content, export_type) do
    "./#{file_folder()}/#{get_file_name(export_type)}"
    |> File.write(content)
    |> resolve_result()
  end

  @spec read_main_file_from_storage(binary) :: {:ok, binary} | {:error, any}
  def read_main_file_from_storage(export_type) do
    "./#{file_folder()}/#{get_file_name(export_type)}"
    |> File.read()
    |> resolve_result()
  end

  defp get_folder_path(%Export{id: id}), do: "./#{file_folder()}/#{id}/"

  defp get_file_name(organization_reference)
       when is_binary(organization_reference) and organization_reference != "" do
    "#{organization_reference}.xml"
  end

  defp get_file_name(organization_reference), do: organization_reference

  defp resolve_result(result) do
    case result do
      :ok ->
        {:ok, ""}

      other_result ->
        other_result
    end
  end
end
