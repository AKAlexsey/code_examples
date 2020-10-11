defmodule TaskArchitecture.Exports.FiltrationRulesFormObject do
  @moduledoc """
  Contains logic to create and edit filtration rules
  """

  import Ecto.Changeset

  alias Ecto.Embedded
  alias TaskArchitecture.Changeset.AttrsNormalizer
  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.ExportCompany
  alias TaskArchitecture.Exports.ExportCompanyEmbedded.Rule

  defstruct export_company: nil,
            filtration_rule_id: nil,
            rules: []

  @schema %{
    export_company: %ExportCompany{},
    filtration_rule_id: :binary,
    rules: {:array, Rule}
  }

  @type t :: %__MODULE__{}

  # Public API
  @spec new(ExportCompany.t(), binary | nil) :: t
  def new(%ExportCompany{} = export_company, filtration_rule_id \\ nil) do
    %__MODULE__{
      filtration_rule_id: filtration_rule_id,
      rules: get_rules(export_company, filtration_rule_id),
      export_company: export_company
    }
  end

  @spec get_rules(ExportCompany.t(), binary | nil) :: list(Rule.t())
  defp get_rules(%{} = export_company, filtration_rule_id) when is_binary(filtration_rule_id) do
    export_company
    |> find_rules_by_id(filtration_rule_id)
    |> case do
      nil ->
        get_rules(export_company, nil)

      %{rules: rules_list} ->
        rules_list
    end
  end

  defp get_rules(_export_company, nil) do
    [%Rule{}]
  end

  defp find_rules_by_id(%{filtration_rules: rules}, filtration_rule_id) when is_list(rules) do
    rules
    |> Enum.find(fn %{id: id} -> id == filtration_rule_id end)
  end

  defp find_rules_by_id(_, _), do: nil

  @spec changeset(ExportCompany.t(), binary | nil) :: Ecto.Changeset.t()
  def changeset(%ExportCompany{} = export_company, filtration_rule_id \\ nil) do
    form_object = export_company |> new(filtration_rule_id)

    {form_object, inject_embeds_many(@schema)}
    |> change()
  end

  defp inject_embeds_many(schema) do
    rules = {
      :embed,
      %Embedded{
        cardinality: :many,
        field: :filtration_rules,
        on_cast: &Rule.changeset/2,
        on_replace: :delete,
        ordered: true,
        owner: FiltrationRulesFormObject,
        related: Rule,
        unique: true
      }
    }

    Map.put(schema, :rules, rules)
  end

  def __changeset__, do: @schema

  @spec create_filtration_rule(ExportCompany.t(), map) :: {:ok, t} | {:error, any}
  def create_filtration_rule(%__MODULE__{} = form_object, filtration_rules_params) do
    normalized_attrs = normalize_attrs(filtration_rules_params)

    cast_result = cast_rules(normalized_attrs)

    if cast_invalid?(cast_result) do
      invalid_changeset(form_object, cast_result)
    else
      add_filtration_rule(form_object, normalized_attrs)
    end
  end

  @spec update_filtration_rule(ExportCompany.t(), map) :: {:ok, t} | {:error, any}
  def update_filtration_rule(%__MODULE__{filtration_rule_id: nil} = form_object, _) do
    form_object
    |> change(%{})
    |> add_error(:filtration_rule_id, "can't be blank")
    |> (fn result -> {:error, result} end).()
  end

  def update_filtration_rule(%__MODULE__{} = form_object, filtration_rules_params) do
    normalized_attrs = normalize_attrs(filtration_rules_params)

    cast_result = cast_rules(normalized_attrs)

    if cast_invalid?(cast_result) do
      invalid_changeset(form_object, cast_result)
    else
      modify_filtration_rule(form_object, normalized_attrs)
    end
  end

  @spec delete_filtration_rule(t) :: :ok | {:error, binary}
  def delete_filtration_rule(%__MODULE__{filtration_rule_id: nil}) do
    {:error, "Form object does not have :filtration_rule_id"}
  end

  def delete_filtration_rule(
        %__MODULE__{export_company: export_company, filtration_rule_id: filtration_rule_id} =
          form_object
      ) do
    export_company
    |> find_rules_by_id(filtration_rule_id)
    |> case do
      nil ->
        {:error, "Rule with given id does not exist"}

      _ ->
        drop_filtration_rule(form_object)
    end
  end

  # Private functions
  defp cast_invalid?(cast_result) do
    Enum.any?(cast_result, &(not &1.valid?))
  end

  defp invalid_changeset(form_object, cast_result) do
    {form_object, inject_embeds_many(@schema)}
    |> change(%{rules: cast_result})
    |> add_error(:rules, "Some rules invalid")
    |> (fn error_changeset -> {:error, error_changeset} end).()
  end

  defp add_filtration_rule(form_object, normalized_attrs) do
    %{export_company: export_company} = form_object
    previous_filtration_rules = previous_filtration_rules_params(export_company)

    export_company
    |> Exports.update_export_company(%{
      filtration_rules: previous_filtration_rules ++ [%{rules: normalized_attrs}]
    })
    |> (fn {:ok, %{filtration_rules: filtration_rules} = updated_export_company} ->
          filtration_rule_id = find_filtration_rule_id(filtration_rules, normalized_attrs)
          {:ok, new(updated_export_company, filtration_rule_id)}
        end).()
  end

  defp modify_filtration_rule(form_object, normalized_attrs) do
    %{
      export_company: export_company,
      filtration_rule_id: filtration_rule_id
    } = form_object

    modified_filtration_rules =
      export_company
      |> previous_filtration_rules_params()
      |> modify_filtration_rule_by_params(filtration_rule_id, normalized_attrs)

    export_company
    |> Exports.update_export_company(%{
      filtration_rules: modified_filtration_rules
    })
    |> (fn {:ok, %{filtration_rules: filtration_rules} = updated_export_company} ->
          filtration_rule_id = find_filtration_rule_id(filtration_rules, normalized_attrs)
          {:ok, new(updated_export_company, filtration_rule_id)}
        end).()
  end

  defp modify_filtration_rule_by_params(previous_rules_params, filtration_rule_id, update_params) do
    previous_rules_params
    |> Enum.map(fn rule_params ->
      if Map.get(rule_params, :id) == filtration_rule_id do
        %{id: filtration_rule_id, rules: update_params}
      else
        rule_params
      end
    end)
  end

  @spec drop_filtration_rule(t) :: :ok
  defp drop_filtration_rule(%{
         export_company: export_company,
         filtration_rule_id: filtration_rule_id
       }) do
    export_company
    |> previous_filtration_rules_params()
    |> Enum.map(fn %{id: id} = filtration_rules ->
      if(id == filtration_rule_id, do: nil, else: filtration_rules)
    end)
    |> Enum.reject(&is_nil(&1))
    |> (fn new_filtration_rules_params ->
          export_company
          |> Exports.update_export_company(%{filtration_rules: new_filtration_rules_params})
        end).()

    :ok
  end

  defp find_filtration_rule_id(filtration_rules, normalized_attrs) do
    filtration_rules
    |> Enum.find(fn %{rules: rules} ->
      with true <- length(rules) == length(normalized_attrs),
           true <- order_rules(rules) == order_rules(normalized_attrs) do
        true
      else
        _ ->
          false
      end
    end)
    |> case do
      nil ->
        nil

      %{id: id} ->
        id
    end
  end

  defp order_rules(rules) do
    rules
    |> Enum.sort_by(fn %{field: field, value: value, operation: operation} ->
      "#{field}#{value}#{operation}"
    end)
  end

  defp cast_rules(rules) do
    rules
    |> Enum.map(&Rule.changeset(%Rule{}, &1))
  end

  defp normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Map.values()
    |> List.flatten()
    |> normalize_attrs()
  end

  defp normalize_attrs(attrs) when is_list(attrs) do
    attrs
    |> Enum.map(&AttrsNormalizer.normalize(&1, %{}))
  end

  defp previous_filtration_rules_params(%{filtration_rules: filtration_rules}) do
    filtration_rules
    |> Enum.map(fn %{rules: rules, id: id} ->
      rules
      |> Enum.map(&Map.from_struct/1)
      |> (fn params_list -> %{rules: params_list, id: id} end).()
    end)
  end
end
