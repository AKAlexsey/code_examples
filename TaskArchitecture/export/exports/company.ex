defmodule TaskArchitecture.Exports.Company do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TaskArchitecture.Exports.CompanyEmbedded.ApecManualFields
  alias TaskArchitecture.Exports.ExportCompany

  @cast_fields [:organization_reference, :access_token]
  @required_fields [:organization_reference, :access_token]

  @type t :: %__MODULE__{}

  schema "exports_companies" do
    field :organization_reference, :string
    field :access_token, :string

    has_many :export_companies, ExportCompany, on_delete: :delete_all, on_replace: :delete
    has_many :exports, through: [:export_companies, :export], on_delete: :nothig

    embeds_one :apec_manual_fields, ApecManualFields, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:export_companies, with: &ExportCompany.changeset/2)
    |> unique_constraint(:organization_reference,
      name: :exports_companies_organization_reference_index
    )
    |> cast_embed(:apec_manual_fields, with: &ApecManualFields.changeset/2)
  end
end
