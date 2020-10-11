defmodule TaskArchitecture.Services.Export.StorageClient do
  @moduledoc """
  Perform saving and reading files from storage.
  Using S3 in production and just special folder locally.
  Import inside itself module appropriate to the environment.
  """

  @behaviour TaskArchitecture.Services.Export.StorageClientBehaviour

  alias TaskArchitecture.Exports.Export
  alias TaskArchitecture.Services.Export.StorageClient.{DevStorage, ProductionStorage}

  if Mix.env() == :dev || Mix.env() == :test do
    defdelegate write_to_storage(content, organization_reference, export), to: DevStorage
    defdelegate read_from_storage(organization_reference, export), to: DevStorage
    defdelegate delete_from_storage(organization_reference, export), to: DevStorage
    defdelegate write_main_file_to_storage(content, export_type), to: DevStorage
    defdelegate read_main_file_from_storage(export_type), to: DevStorage
  else
    defdelegate write_to_storage(content, organization_reference, export), to: ProductionStorage
    defdelegate read_from_storage(organization_reference, export), to: ProductionStorage
    defdelegate delete_from_storage(organization_reference, export), to: ProductionStorage
    defdelegate write_main_file_to_storage(content, export_type), to: ProductionStorage
    defdelegate read_main_file_from_storage(export_type), to: ProductionStorage
  end

  @spec write_files_to_store(list, Export) :: {:ok, {list, list}} | {:error, any}
  def write_files_to_store([], %Export{}), do: {:error, "No files given"}

  def write_files_to_store(list, %Export{} = export) do
    list
    |> Enum.reduce_while({[], []}, fn
      {company, xml_file}, {success_list, fail_list} ->
        write_to_storage(xml_file, company.organization_reference, export)
        |> case do
          {:ok, _} ->
            {:cont, {[{company, "ok"}] ++ success_list, fail_list}}

          {:error, reason} ->
            {:cont,
             {success_list, [{company, "#{inspect(reason, length: :infinity)}"}] ++ fail_list}}
        end

      _, {_, _} ->
        {:halt, {:error, "Wrong files list format"}}
    end)
    |> (fn result -> {:ok, result} end).()
  end
end
