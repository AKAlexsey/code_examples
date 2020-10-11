defmodule TaskArchitecture.Services.Export.ConvertToFile do
  @moduledoc """
  Router that define which export module it's necessary to use to export to specific XML structure.
  """

  alias TaskArchitecture.Exports.Export
  alias TaskArchitecture.Model.PlatformJobEntity
  alias TaskArchitecture.Services.ConvertToFile.Apec

  @spec call(Export.t(), list(PlatformJobEntity)) :: {:ok, {list, list}} | {:error, binary}
  def call(%Export{} = export, valid_companies_jobs) when is_list(valid_companies_jobs) do
    case export do
      %{export_target_type: :apec} ->
        Apec.call(valid_companies_jobs)

      %{export_target_type: type} ->
        {:error, "Unknown Export type #{type}"}
    end
  end
end
