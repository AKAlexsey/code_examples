defmodule TaskArchitecture.Exports.ExportCompanyFormObject do
  @moduledoc """
  Represents data structure of the form object for creating new export company
  """

  alias TaskArchitecture.Changeset.AttrsNormalizer
  alias TaskArchitecture.Exports
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  defstruct export_id: nil,
            organization_reference: nil,
            access_token: nil,
            company_id: nil

  @schema %{
    export_id: :integer,
    company_id: :integer,
    organization_reference: :string,
    access_token: :string
  }
  @cast_fields Map.keys(@schema)

  @normalize_configurations %{
    export_id: &AttrsNormalizer.string_to_integer/1,
    company_id: &AttrsNormalizer.string_to_integer/1
  }

  @spec new(map) :: t
  def new(attrs \\ %{}) do
    {valid_attrs, _} = Map.split(attrs, Map.keys(@schema))

    %__MODULE__{}
    |> Map.merge(valid_attrs)
  end

  @spec changeset(map) :: Ecto.Changeset.t()
  def changeset(attrs \\ %{}) do
    attrs
    |> new()
    |> change()
  end

  def __changeset__, do: @schema

  @spec create(t, map) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def create(%__MODULE__{} = struct, attrs \\ %{}) when is_map(attrs) do
    normalized_attrs = AttrsNormalizer.normalize(attrs, @normalize_configurations)

    {struct, @schema}
    |> cast(normalized_attrs, @cast_fields)
    |> create_records_in_db()
    |> resolve_result()
  end

  defp create_records_in_db(%{changes: changes} = changeset) do
    export_id = Map.get(changes, :export_id)
    company_id = Map.get(changes, :company_id)
    organization_reference = Map.get(changes, :organization_reference)
    access_token = Map.get(changes, :access_token)

    with true <- changeset.valid?,
         {:ok, updated_export_company} <-
           Exports.create_export_company_with_company(%{
             export_id: export_id,
             company_id: company_id,
             organization_reference: organization_reference,
             access_token: access_token
           }) do
      case updated_export_company do
        %{company: %{id: company_id}} ->
          cast(changeset, %{company_id: company_id}, [:company_id])

        _ ->
          changeset
      end
    else
      false ->
        changeset

      {:error, :export_company, %{errors: errors}, _} ->
        errors
        |> Enum.reduce(changeset, fn {field, {message, keys}}, err_changeset ->
          add_error(err_changeset, field, message, keys)
        end)
        |> validate_required([:export_id, :company_id])

      {:error, :company, %{errors: errors}, _} ->
        errors
        |> Enum.reduce(changeset, fn {field, {message, keys}}, err_changeset ->
          add_error(err_changeset, field, message, keys)
        end)
        |> validate_required([:export_id, :organization_reference, :access_token])
    end
  end

  defp resolve_result(changeset) do
    case changeset do
      %{valid?: true, changes: changes} ->
        changes
        |> new()
        |> (fn result -> {:ok, result} end).()

      invalid_changeset ->
        {:error, invalid_changeset}
    end
  end
end
