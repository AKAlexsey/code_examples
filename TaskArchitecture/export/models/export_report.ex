defmodule TaskArchitecture.Model.ExportReport do
  @moduledoc """
  Struct and it's methods to put different export process info during export
  """
  @type t :: %__MODULE__{}

  alias TaskArchitecture.Exports.Export

  defstruct export: nil,
            failed_export: false,
            start_type: nil,
            export_job: nil,
            # :get_export_companies stage
            companies_list: [],
            # :fetch_offices_for_companies stage
            successful_company_offices_list: [],
            # :fetch_job_offers_for_companies stage
            companies_jobs: [],
            # :filter_job_offers_by_limitations stage
            filtered_by_limitations: [],
            # :validate_job_offers stage
            valid_companies_jobs: [],
            # :convert_job_offers_to_files stage
            successful_converted: [],
            # :send_xml_files_to_store stage
            successful_sent: [],
            # common errors structure
            failed_reasons: [],
            # common store for failed results
            failed_results: %{}

  def new(%Export{} = export, start_type) do
    %__MODULE__{export: export, start_type: start_type}
  end

  def add(report, field, result, fun \\ fn val -> val end)

  def add(%__MODULE__{failed_export: false} = report, field, {:ok, result}, fun)
      when is_function(fun) do
    what_to_add = fun.(result)
    Map.put(report, field, what_to_add)
  end

  def add(
        %__MODULE__{failed_export: false} = report,
        field,
        {:error, _reason} = error_tuple,
        _fun
      ) do
    report
    |> Map.put(field, error_tuple)
    |> Map.put(:failed_export, true)
  end

  # skip all and pass next
  def add(%__MODULE__{failed_export: true} = report, _, _, _), do: report

  @doc "Adds entity to list of entities"
  def add_to_list(%__MODULE__{} = report, key, val) do
    old_val = Map.from_struct(report)[key]

    cond do
      is_list(old_val) and is_list(val) ->
        Map.put(report, key, val ++ old_val)

      is_list(old_val) ->
        Map.put(report, key, [val] ++ old_val)

      true ->
        raise ArgumentError, "passed add_to_list field #{inspect(key)} should be list"
    end
  end

  def put_to_map(%__MODULE__{} = report, report_field, map_key, result) do
    old_val = Map.from_struct(report)[report_field]

    if is_map(old_val) do
      new_val = Map.put(old_val, map_key, result)
      Map.put(report, report_field, new_val)
    else
      raise ArgumentError, ":report_field in put_to_map should be map"
    end
  end

  def add_failed_result(%__MODULE__{} = report, map_key, result) do
    put_to_map(report, :failed_results, map_key, result)
  end

  @doc "Increments counter in SyncReport struct"
  def incr(report, key, incr_val \\ 1)

  def incr(%__MODULE__{failed_export: false} = report, key, incr_val) do
    val = Map.from_struct(report)[key]

    if is_integer(val) do
      Map.put(report, key, val + incr_val)
    else
      raise ArgumentError, "passed increment field should be integer"
    end
  end

  def incr(%__MODULE__{failed_export: true} = report, _key, _val), do: report

  def fail(%__MODULE__{} = report), do: Map.put(report, :failed_export, true)
end
