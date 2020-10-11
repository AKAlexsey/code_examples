defmodule TaskArchitecture.Services.Export.StorageClient.ProductionStorage do
  @moduledoc """
  Represent interface or reading and writing file for production environment
  """

  @behaviour TaskArchitecture.Services.Export.StorageClientBehaviour

  alias ExAws.S3
  alias TaskArchitecture.Exports.Export
  alias TaskArchitecture.Services.Export.StorageClient

  @file_folder "feed_files"
  @temporary_folder "tmp/feed_files/"
  @maximum_timeout 120_000
  @link_expiring_seconds 60

  @spec write_to_storage(binary, binary, Export.t()) :: :ok | {:error, any}
  def write_to_storage(file_content, organization_reference, %Export{} = export) do
    part_file_path = get_part_file_path(organization_reference, export)

    save_file_to_storage(file_content, part_file_path)
  end

  @spec read_from_storage(binary, Export.t()) :: {:ok, binary} | {:error, any}
  def read_from_storage(organization_reference, %Export{} = export) do
    part_file_path = get_part_file_path(organization_reference, export)

    if file_exist_on_storage?(part_file_path) do
      download_file_content(part_file_path)
    else
      {:error, "File not found"}
    end
  end

  defp download_file_content(part_file_path) do
    with store_file_path <- get_store_file_path(part_file_path),
         {:ok, temporary_file_path} <-
           save_temporary_file("", "download/#{part_file_path}"),
         {:ok, _} <- download_the_file(store_file_path, temporary_file_path),
         {:ok, content} <- File.read(temporary_file_path) do
      {:ok, content}
    else
      {:error, reason} ->
        {:error, reason}
    end
  after
    remove_temporary_file("download/#{part_file_path}")
  end

  defp download_the_file(store_file_path, temporary_file_path) do
    get_bucket_name()
    |> ExAws.S3.download_file(store_file_path, temporary_file_path, expires_in: @maximum_timeout)
    |> ExAws.request()
    |> resolve_request_result()
  end

  # This function is not used anywhere and moreover
  # user does not have rights to delete files but still this function should exist
  @spec delete_from_storage(binary, Export.t()) :: :ok | {:error, any}
  def delete_from_storage(organization_reference, %Export{} = export) do
    store_file_path = get_store_file_path(get_part_file_path(organization_reference, export))

    get_bucket_name()
    |> S3.delete_object(store_file_path)
    |> ExAws.request()
    |> resolve_request_result()
  end

  @spec write_main_file_to_storage(binary, binary) :: {:ok, binary} | {:error, any}
  def write_main_file_to_storage(file_content, export_type) do
    file_name = get_file_name(export_type)

    save_file_to_storage(file_content, file_name)
  end

  @spec read_main_file_from_storage(binary) :: {:ok, binary} | {:error, any}
  def read_main_file_from_storage(export_type) do
    file_name = get_file_name(export_type)

    if file_exist_on_storage?(file_name) do
      store_file_path = get_store_file_path(file_name)

      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(:get, get_bucket_name(), store_file_path,
        expires_in: @link_expiring_seconds
      )
      |> resolve_request_result()
    else
      {:error, "File not found"}
    end
  end

  # Common functions
  @spec file_exist_on_storage?(binary) :: boolean
  defp file_exist_on_storage?(part_file_path) do
    with {:ok, %{body: %{contents: files_list}}} <- fetch_files_from_bucket(),
         store_file_path <- get_store_file_path(part_file_path),
         file_metadata when is_map(file_metadata) <-
           Enum.find(files_list, &(&1.key == store_file_path)) do
      true
    else
      _ ->
        false
    end
  end

  defp fetch_files_from_bucket do
    S3.list_objects(get_bucket_name(), prefix: get_namespace())
    |> ExAws.request()
  end

  @spec save_file_to_storage(binary, binary) :: {:ok, binary} | {:error, any}
  defp save_file_to_storage(file_content, relative_path) do
    with store_file_path <- get_store_file_path(relative_path),
         {:ok, temporary_file_path} <-
           save_temporary_file(file_content, relative_path),
         {:ok, body} <- send_file_to_s3(temporary_file_path, store_file_path) do
      {:ok, body}
    else
      {:error, reason} ->
        {:error, reason}
    end
  after
    remove_temporary_file(relative_path)
  end

  defp get_part_file_path(organization_reference, %Export{id: id}) do
    "#{id}/#{get_file_name(organization_reference)}"
  end

  defp get_store_file_path(relative_path) do
    "#{get_namespace()}/#{@file_folder}/#{relative_path}"
  end

  @spec save_temporary_file(binary, binary) :: {:ok, binary} | {:error, binary}
  defp save_temporary_file(file_content, relative_file_path) do
    file_path = "#{@temporary_folder}#{relative_file_path}"
    create_folders(file_path)

    case File.write("./#{file_path}", file_content) do
      :ok ->
        {:ok, "./#{file_path}"}

      {:error, reason} ->
        {:error, inspect_reason(reason)}
    end
  end

  defp remove_temporary_file(file_path) do
    "./#{@temporary_folder}#{file_path}"
    |> File.rm()
  end

  @spec send_file_to_s3(binary, binary) :: {:ok, map} | {:error, any}
  defp send_file_to_s3(temporary_file_path, store_file_path) do
    temporary_file_path
    |> S3.Upload.stream_file()
    |> S3.upload(get_bucket_name(), store_file_path, timeout: @maximum_timeout)
    |> ExAws.request()
    |> resolve_request_result()
  end

  defp resolve_request_result(result) do
    result
    |> case do
      {:ok, %{body: body}} ->
        {:ok, body}

      {:ok, value} ->
        {:ok, value}

      {:error, reason} ->
        {:error, inspect_reason(reason)}
    end
  end

  defp get_file_name(organization_reference)
       when is_binary(organization_reference) and organization_reference != "" do
    "#{organization_reference}.xml"
  end

  @spec create_folders(binary) :: :ok | {:error, any}
  defp create_folders(path) do
    path
    |> String.split("/")
    |> Enum.reduce_while(
      "",
      fn
        segment, acc ->
          if String.contains?(segment, ".xml") do
            {:halt, :ok}
          else
            full_path = "#{acc}/#{segment}"
            File.mkdir("./#{full_path}")
            {:cont, full_path}
          end
      end
    )
  end

  defp get_namespace do
    Application.get_env(:jobs_importer, StorageClient)[:namespace]
  end

  defp get_bucket_name do
    Application.get_env(:jobs_importer, StorageClient)[:bucket_name]
  end

  defp inspect_reason(reason) when is_binary(reason), do: reason
  defp inspect_reason(reason), do: inspect(reason)
end
