defmodule TaskArchitecture.Services.Export.ExportFilter do
  @moduledoc """
  Perform filtering
  """

  alias TaskArchitecture.Exports.{Company, Export}
  alias TaskArchitecture.Exports.ExportCompanyEmbedded.FiltrationRules
  alias TaskArchitecture.Model.PlatformJobEntity

  @spec perform(list(tuple), Export.t()) :: list(tuple)
  def perform(companies_jobs_list, export) do
    companies_jobs_list
    |> Enum.map(fn {company, records} ->
      filtered_records = make_filtration_function(company, export).(records)
      if(filtered_records == [], do: nil, else: {company, filtered_records})
    end)
    |> Enum.filter(&(not is_nil(&1)))
  end

  @spec make_filtration_function(Company.t(), Export.t()) :: (list -> list)
  defp make_filtration_function(%{export_companies: export_companies}, %{id: export_id}) do
    %{filtration_rules: filtration_rules} =
      Enum.find(export_companies, &(&1.export_id == export_id))

    rules_groups_predicate = make_rules_groups_predicate(filtration_rules)

    fn jobs_list ->
      jobs_list
      |> Enum.filter(&rules_groups_predicate.(&1))
    end
  end

  defp make_filtration_function(_, _) do
    fn jobs_list -> jobs_list end
  end

  @spec make_rules_groups_predicate(list(FiltrationRules.t())) ::
          (PlatformJobEntity.t() -> boolean)
  defp make_rules_groups_predicate(rules_groups)
       when is_list(rules_groups) and rules_groups != [] do
    groups_predicates =
      rules_groups
      |> Enum.map(&make_group_predicate/1)

    fn job ->
      Enum.reduce(groups_predicates, false, fn predicate, result ->
        predicate.(job) || result
      end)
    end
  end

  defp make_rules_groups_predicate(_), do: fn _job -> true end

  @spec make_group_predicate(list) :: (PlatformJobEntity.t() -> boolean)
  defp make_group_predicate(%FiltrationRules{rules: rules}) when is_list(rules) and rules != [] do
    groups_predicates_params =
      rules
      |> Enum.map(fn %{field: field, value: value, operation: operation} ->
        {String.to_existing_atom(field), value, get_operation_function(operation)}
      end)

    fn job ->
      groups_predicates_params
      |> apply_predicates_on_job(job)
    end
  end

  defp make_group_predicate(_) do
    fn _job -> true end
  end

  defp apply_predicates_on_job(predicates, job) do
    predicates
    |> Enum.reduce_while(true, fn {field, equal_value, operation_function}, previous_result ->
      value = Map.get(job, field)
      result = operation_function.("#{value}", equal_value)
      if(result && previous_result, do: {:cont, true}, else: {:halt, false})
    end)
  end

  @spec get_operation_function(binary) :: (any, any -> boolean)
  defp get_operation_function("equal"), do: &Kernel.==/2
  defp get_operation_function("contains"), do: &Kernel.=~/2

  defp get_operation_function(unknown_type) do
    raise "Unknown operation type #{unknown_type}"
  end
end
