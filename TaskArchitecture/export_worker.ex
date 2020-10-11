defmodule TaskArchitecture.Services.Export.ExportWorker do
  @moduledoc """
  Perform fetching the job offers and saving them into file storage.
  """

  require Logger

  alias TaskArchitecture.Common.ExceptionFormatter
  alias TaskArchitecture.Exports.Export
  alias TaskArchitecture.Model.ExportReport

  alias TaskArchitecture.Services.Export.{
    ConvertToFile,
    CreateExportJob,
    ExportCompaniesFetcher,
    ExportFilter,
    JobOffersFetcher,
    JobOffersValidator,
    JobOfficesFetcher,
    StorageClient
  }

  alias JobsImporterWeb.DisplayDatetimeHelpers

  @spec run(Export.t(), list) :: {:ok, ExportReport.t()} | {:error, any}
  def run(%Export{} = export, options) do
    start_type = Keyword.get(options, :start_type)

    Logger.info(
      "Run #{__MODULE__} for Export: \"#{export.name}\" at #{
        DisplayDatetimeHelpers.display_datetime(NaiveDateTime.utc_now())
      }"
    )

    ExportReport.new(export, start_type)
    |> run_stage(&get_export_companies/1)
    |> run_stage(&fetch_offices_for_companies/1)
    |> run_stage(&fetch_job_offers_for_companies/1)
    |> run_stage(&filter_job_offers_by_limitations/1)
    |> run_stage(&validate_job_offers/1)
    |> run_stage(&convert_job_offers_to_files/1)
    |> run_stage(&save_xml_files_to_store/1)
    |> create_report()
    |> resolve_result()
  rescue
    error ->
      start_type = Keyword.get(options, :start_type)
      emergency_make_report(export, start_type, error, __STACKTRACE__)
  catch
    :exit, error ->
      start_type = Keyword.get(options, :start_type)
      emergency_make_report(export, start_type, error, __STACKTRACE__)
  end

  @spec get_export_companies(ExportReport.t()) :: ExportReport.t()
  defp get_export_companies(%ExportReport{export: export} = export_report) do
    function_name = get_function_name(__ENV__.function)

    export
    |> ExportCompaniesFetcher.call()
    |> case do
      {:error, reason} ->
        export_report
        |> add_failed_reason(function_name, reason)
        |> ExportReport.fail()

      {:ok, {success_list, failed_list}} ->
        export_report
        |> add_failed_reasons_if_necessary(
          function_name,
          {success_list, failed_list},
          "Companies invalid"
        )
        |> ExportReport.add_to_list(:companies_list, success_list)
    end
  end

  @spec fetch_offices_for_companies(ExportReport.t()) :: ExportReport.t()
  defp fetch_offices_for_companies(
         %ExportReport{
           export: export,
           companies_list: companies_list
         } = export_report
       ) do
    function_name = get_function_name(__ENV__.function)

    companies_list
    |> JobOfficesFetcher.call(export)
    |> case do
      {:error, reason} ->
        export_report
        |> add_failed_reason(function_name, reason)
        |> ExportReport.fail()

      {:ok, {success_list, failed_list}} ->
        export_report
        |> add_failed_reasons_if_necessary(
          function_name,
          {success_list, failed_list},
          "No offices."
        )
        |> ExportReport.add_to_list(:successful_company_offices_list, success_list)
    end
  end

  @spec fetch_job_offers_for_companies(ExportReport.t()) :: ExportReport.t()
  defp fetch_job_offers_for_companies(
         %ExportReport{
           export: export,
           companies_list: companies_list,
           successful_company_offices_list: successful_company_offices_list
         } = export_report
       ) do
    function_name = get_function_name(__ENV__.function)

    companies_list
    |> JobOffersFetcher.call(successful_company_offices_list, export)
    |> case do
      {:error, reason} ->
        export_report
        |> add_failed_reason(function_name, reason)
        |> ExportReport.fail()

      {:ok, {success_list, failed_list}} ->
        export_report
        |> add_failed_reasons_if_necessary(
          function_name,
          {success_list, failed_list},
          "No job offers."
        )
        |> ExportReport.add_to_list(:companies_jobs, success_list)
    end
  end

  @spec filter_job_offers_by_limitations(ExportReport.t()) :: ExportReport.t()
  defp filter_job_offers_by_limitations(
         %ExportReport{
           export: export,
           companies_jobs: companies_jobs
         } = export_report
       ) do
    %{export_report | filtered_by_limitations: ExportFilter.perform(companies_jobs, export)}
  end

  @spec validate_job_offers(ExportReport.t()) :: ExportReport.t()
  defp validate_job_offers(
         %ExportReport{
           filtered_by_limitations: filtered_by_limitations
         } = export_report
       ) do
    function_name = get_function_name(__ENV__.function)

    filtered_by_limitations
    |> JobOffersValidator.call()
    |> case do
      {:error, reason} ->
        export_report
        |> add_failed_reason(function_name, reason)
        |> ExportReport.fail()

      {:ok, {success_list, failed_list}} ->
        export_report
        |> add_failed_reasons_if_necessary(
          function_name,
          {success_list, failed_list},
          "No successfully converted records."
        )
        |> ExportReport.add_to_list(:valid_companies_jobs, success_list)
    end
  end

  @spec convert_job_offers_to_files(ExportReport.t()) :: ExportReport.t()
  defp convert_job_offers_to_files(
         %ExportReport{
           export: export,
           valid_companies_jobs: valid_companies_jobs
         } = export_report
       ) do
    function_name = get_function_name(__ENV__.function)

    export
    |> ConvertToFile.call(valid_companies_jobs)
    |> case do
      {:error, reason} ->
        export_report
        |> add_failed_reason(function_name, reason)
        |> ExportReport.fail()

      {:ok, {success_list, failed_list}} ->
        export_report
        |> add_failed_reasons_if_necessary(
          function_name,
          {success_list, failed_list},
          "No successfully converted records."
        )
        |> ExportReport.add_to_list(:successful_converted, success_list)
    end
  end

  @spec save_xml_files_to_store(ExportReport.t()) :: ExportReport.t()
  defp save_xml_files_to_store(
         %ExportReport{
           export: export,
           successful_converted: successful_converted
         } = export_report
       ) do
    function_name = get_function_name(__ENV__.function)

    successful_converted
    |> StorageClient.write_files_to_store(export)
    |> case do
      {:error, reason} ->
        export_report
        |> add_failed_reason(function_name, reason)
        |> ExportReport.fail()

      {:ok, {success_list, failed_list}} ->
        export_report
        |> add_failed_reasons_if_necessary(
          function_name,
          {success_list, failed_list},
          "No records for saved to store."
        )
        |> ExportReport.add_to_list(:successful_sent, success_list)
    end
  end

  @spec create_report(ExportReport.t()) :: ExportReport.t()
  defp create_report(%ExportReport{export: %{id: export_id, name: export_name}} = export_report) do
    CreateExportJob.perform(
      export_report,
      NaiveDateTime.utc_now()
    )
    |> case do
      {:ok, export_job} ->
        Logger.info(
          "CreateExportJob report for export: ID: #{export_id}, name: #{export_name}, has been successfully created."
        )

        export_report
        |> ExportReport.add(:export_job, {:ok, export_job})

      {:error, reason} ->
        Logger.error("Error creating job report. Reason #{inspect(reason)}")
        raise("Unable to create report. Reason: #{inspect(reason)}")
    end
  end

  @spec emergency_make_report(Export.t(), String.t(), any, any) :: {:error, binary}
  defp emergency_make_report(export, start_type, error, stacktrace) do
    reason_with_stacktrace = ExceptionFormatter.format_error(error, stacktrace)

    failed_export_report =
      ExportReport.new(export, start_type)
      |> ExportReport.add_to_list(
        :failed_reasons,
        {"Unexpected error", nil, reason_with_stacktrace}
      )
      |> ExportReport.fail()

    create_report(failed_export_report)
    {:error, reason_with_stacktrace}
  end

  @spec run_stage(ExportReport.t(), (... -> any), list) :: ExportReport.t()
  defp run_stage(_export_report, _function, opts \\ [])

  defp run_stage(%{failed_export: false} = export_report, function, opts) do
    apply(function, [export_report] ++ opts)
  end

  defp run_stage(%{failed_export: true} = export_report, _function, _opts) do
    export_report
  end

  defp add_failed_reason(export_report, function_name, reason) do
    export_report
    |> ExportReport.add_to_list(
      :failed_reasons,
      {"Fail reason on: #{to_string(function_name)}", function_name, reason}
    )
  end

  defp add_failed_reasons_if_necessary(
         export_report,
         function_name,
         {success_list, failed_list},
         error_message
       ) do
    export_report
    |> (fn report ->
          if failed_list == [] do
            report
          else
            report
            |> add_failed_reason(function_name, error_message)
            |> ExportReport.add_failed_result(function_name, failed_list)
          end
        end).()
    |> (fn report ->
          if success_list == [] do
            report
            |> add_failed_reason(function_name, "No success results")
            |> ExportReport.fail()
          else
            report
          end
        end).()
  end

  defp resolve_result(result) do
    case result do
      %ExportReport{} = report ->
        {:ok, report}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_function_name({function_name, _}), do: function_name
end
