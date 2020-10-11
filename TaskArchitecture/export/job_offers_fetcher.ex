defmodule TaskArchitecture.Services.Export.JobOffersFetcher do
  @moduledoc """
  Concurrently fetch job offers according to the configurations given as peremeter
  """

  @default_fetch_job_offers_timeout 300_000

  require Logger
  alias TaskArchitecture.Common.ExceptionFormatter
  alias TaskArchitecture.DataTargets.Platform.ApiClient
  alias TaskArchitecture.Exports.{Company, Export}
  alias TaskArchitecture.Services.Export.ExportToTarget
  alias TaskArchitecture.ToPlatform.Behaviours.WithOffice

  @spec call(list, list, Export.t()) :: {:ok, {list(tuple), list(tuple)}} | {:error, binary}
  def call([], _list, _export), do: {:error, "No companies configurations given as parameter"}

  def call(companies_list, offices_list, %Export{} = export) do
    Task.async_stream(
      companies_list,
      fn %Company{} = company ->
        Process.flag(:trap_exit, true)

        case ExportToTarget.perform(company, export) do
          {:ok, target} ->
            ApiClient.get_all_jobs(target, status: "published")

          {:error, reason} ->
            {:error, reason}
        end
      end,
      timeout: @default_fetch_job_offers_timeout,
      on_timeout: :kill_task
    )
    |> Stream.with_index()
    |> Enum.reduce({[], []}, fn
      {{:ok, {:ok, []}}, index}, {success_list, failed_list} ->
        company = Enum.at(companies_list, index)

        reason =
          "No job offers for company: ID: #{company.id}, organization_reference: #{
            company.organization_reference
          }"

        {success_list, [{company, reason}] ++ failed_list}

      {{:ok, {:ok, records}}, index}, {success_list, failed_list} ->
        company = Enum.at(companies_list, index)
        company_offices_map = get_company_offices(company, offices_list)
        job_office_with_offices = put_offices_params_to_job_offers(records, company_offices_map)
        {[{company, job_office_with_offices}] ++ success_list, failed_list}

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

  defp get_company_offices(%{id: company_id}, offices_map_list) do
    offices_map_list
    |> Enum.find(fn {%{id: list_company_id}, _} -> list_company_id == company_id end)
    |> (fn {_, offices_map} -> offices_map end).()
  end

  defp put_offices_params_to_job_offers(job_offers, offices_map_list) do
    job_offers
    |> Enum.map(fn %{office_id: office_id} = job_offer ->
      case office_id do
        id when id in [nil, ""] ->
          job_offer

        id ->
          office_params = Map.get(offices_map_list, id)
          put_office_params(job_offer, office_params)
      end
    end)
  end

  defp put_office_params(job_offer, nil), do: job_offer

  defp put_office_params(job_offer, office_params) do
    office_info = WithOffice.convert_office_to_office_info(office_params)

    job_offer
    |> Map.merge(office_info)
  end
end
