defmodule TaskArchitecture.Services.Export.CreateExportJob do
  @moduledoc """
  Contains complimentary logic of making report. Make report using records of the ExportReport
  """

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.{Company, ExportJob}
  alias TaskArchitecture.Model.{ExportReport, PlatformJobEntity}

  @spec perform(ExportReport.t(), NaiveDateTime.t()) ::
          {:ok, ExportJob.t()} | {:error, binary | Ecto.Changeset.t()}
  def perform(%ExportReport{} = export_report, %NaiveDateTime{} = creation_date_time) do
    export_report
    |> get_export_job_params()
    |> Map.put(:datetime, creation_date_time)
    |> Exports.create_export_job()
  end

  def perform(_, _), do: {:error, "Invalid parameters"}

  defp get_export_job_params(%ExportReport{
         failed_export: failed_export,
         failed_reasons: failed_reasons,
         export: export,
         start_type: start_type,
         companies_jobs: companies_jobs,
         companies_list: companies_list,
         filtered_by_limitations: filtered_by_limitations,
         successful_sent: successful_sent,
         valid_companies_jobs: valid_companies_jobs,
         failed_results: failed_results
       }) do
    %{
      successful: get_failed_export(failed_export),
      fail_reason: get_fail_reason(failed_reasons, failed_results),
      exported_count: get_exported_count(failed_export, valid_companies_jobs),
      filtered_count: get_filtered_count(companies_jobs, filtered_by_limitations),
      failed_count: get_failed_count(valid_companies_jobs, filtered_by_limitations),
      export_id: get_export_id(export),
      type: get_export_type(export),
      companies_count: get_companies_count(companies_list, failed_results),
      success_companies_count: get_success_companies_count(failed_export, successful_sent),
      start_type: start_type
    }
  end

  @companies_validation_step :get_export_companies
  defp get_companies_count(companies_list, failed_results) do
    failed_results
    |> Map.get(@companies_validation_step)
    |> case do
      failed_companies when is_list(failed_companies) ->
        length(companies_list) + length(failed_companies)

      _ ->
        length(companies_list)
    end
  end

  defp get_success_companies_count(true, _successful_sent), do: 0
  defp get_success_companies_count(_, successful_sent), do: length(successful_sent)

  defp get_failed_export(value) when is_boolean(value), do: !value
  defp get_failed_export(value), do: value

  defp get_fail_reason([], _), do: %{}

  defp get_fail_reason(failed_reasons, failed_results) do
    failed_reasons
    |> Enum.reverse()
    |> Enum.map(fn {title, step, message} ->
      %{
        title: title,
        message: message,
        stage_errors: make_stage_errors(step, failed_results)
      }
    end)
    |> (fn result ->
          %{stage_fail_reasons: result}
        end).()
  end

  defp make_stage_errors(step, failed_results) do
    failed_results
    |> Map.get(step)
    |> case do
      step_failed_results when is_list(step_failed_results) ->
        step_failed_results
        |> Enum.map(fn {company, error} ->
          %{
            entity: get_entity_reference(company),
            message: make_step_error(error)
          }
        end)

      nil ->
        []
    end
  end

  defp get_entity_reference(%Company{organization_reference: reference}),
    do: "Company: #{reference}"

  defp get_entity_reference(%PlatformJobEntity{
         organization_reference: organization_reference,
         reference: reference
       }) do
    "Company: #{organization_reference}\nJob reference: #{reference}"
  end

  defp get_entity_reference(step_argument), do: inspect(step_argument)

  defp make_step_error({:error, reason}), do: make_step_error(reason)
  defp make_step_error(reason) when is_binary(reason), do: reason
  defp make_step_error(%{export_error_message: message}), do: message
  defp make_step_error(reason), do: inspect(reason)

  defp get_exported_count(false, filtered_by_limitations) do
    filtered_by_limitations
    |> Keyword.values()
    |> List.flatten()
    |> Enum.count()
  end

  defp get_exported_count(_, _), do: 0

  defp get_filtered_count(companies_jobs, filtered_by_limitations) do
    count_jobs(companies_jobs) - count_jobs(filtered_by_limitations)
  end

  defp get_failed_count(valid_companies_jobs, filtered_by_limitations) do
    count_jobs(filtered_by_limitations) - count_jobs(valid_companies_jobs)
  end

  defp count_jobs(export_worker_step_result) when is_list(export_worker_step_result) do
    export_worker_step_result
    |> Enum.map(fn {_, jobs} -> length(jobs) end)
    |> Enum.sum()
  end

  defp get_export_id(%{id: export_id}), do: export_id
  defp get_export_id(_), do: nil

  defp get_export_type(%{export_target_type: export_type}), do: export_type
  defp get_export_type(_), do: nil
end
