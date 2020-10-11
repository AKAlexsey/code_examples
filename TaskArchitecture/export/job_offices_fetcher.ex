defmodule TaskArchitecture.Services.Export.JobOfficesFetcher do
  @moduledoc """
  Concurrently fetch job offers according to the configurations given as peremeter
  """

  @default_fetch_offices_timeout 300_000

  alias TaskArchitecture.Common.ExceptionFormatter
  alias TaskArchitecture.DataTargets.Platform.ApiClient
  alias TaskArchitecture.Exports.{Company, Export}
  alias TaskArchitecture.Services.Export.ExportToTarget

  @spec call(list, Export.t()) :: {:ok, {list(tuple), list(tuple)}} | {:error, binary}
  def call([], _export), do: {:error, "No companies configurations given as parameter"}

  def call(companies_list, %Export{} = export) do
    Task.async_stream(
      companies_list,
      fn %Company{} = company ->
        Process.flag(:trap_exit, true)

        case ExportToTarget.perform(company, export) do
          {:ok, target} ->
            ApiClient.get_all_offices_cached(target)

          {:error, reason} ->
            {:error, reason}
        end
      end,
      timeout: @default_fetch_offices_timeout,
      on_timeout: :kill_task
    )
    |> Stream.with_index()
    |> Enum.reduce({[], []}, fn
      {{:ok, {:ok, []}}, index}, {success_list, failed_list} ->
        company = Enum.at(companies_list, index)

        reason =
          "No offices for company: ID: #{company.id}, organization_reference: #{
            company.organization_reference
          }"

        {success_list, [{company, reason}] ++ failed_list}

      {{:ok, {:ok, records}}, index}, {success_list, failed_list} ->
        offices_map =
          records
          |> Enum.map(fn %{"id" => id} = office ->
            {id, office}
          end)
          |> Enum.into(%{})

        {[{Enum.at(companies_list, index), offices_map}] ++ success_list, failed_list}

      {{:ok, {:error, reason}}, index}, {success_list, failed_list} ->
        {success_list, [{Enum.at(companies_list, index), reason}] ++ failed_list}

      {{:exit, reason}, index}, {success_list, failed_list} ->
        {success_list,
         [
           {Enum.at(companies_list, index), ExceptionFormatter.make_error_message(reason)}
         ] ++ failed_list}
    end)
    |> (fn result -> {:ok, result} end).()
  end
end
