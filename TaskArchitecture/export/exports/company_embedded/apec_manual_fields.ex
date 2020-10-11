defmodule TaskArchitecture.Exports.CompanyEmbedded.ApecManualFields do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @cast_fields [
    :enseigne,
    :raison_sociale,
    :siret,
    :code_naf,
    :limitation_rules,
    :default_min_salary,
    :default_max_salary,
    :default_profile,
    :default_lieu,
    :default_enterprise
  ]
  @required_fields [
    :raison_sociale,
    :siret,
    :code_naf,
    :default_min_salary,
    :default_max_salary,
    :default_profile,
    :default_lieu,
    :default_enterprise
  ]

  @profile_min_length 100
  @enterprise_min_length 100

  @type t :: %__MODULE__{}

  # credo:disable-for-next-line
  # TODO implement common behaviour Requireable that allow to check required fields
  def required_fields, do: @required_fields

  embedded_schema do
    field :enseigne, :string
    field :raison_sociale, :string
    field :siret, :string
    field :code_naf, :string
    field :limitation_rules, :string

    field :default_min_salary, :integer
    field :default_max_salary, :integer
    field :default_profile, :string
    field :default_lieu, :string
    field :default_enterprise, :string
  end

  def profile_min_length, do: @profile_min_length

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_length(:default_profile, min: @profile_min_length)
    |> validate_length(:default_enterprise, min: @enterprise_min_length)
  end
end
