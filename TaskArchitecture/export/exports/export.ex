defmodule TaskArchitecture.Exports.Export do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TaskArchitecture.Exports.{ExportCompany, ExportJob}

  @cast_fields [:name, :active, :export_target_type]
  @required_fields [:name, :active, :export_target_type]

  @type t :: %__MODULE__{}

  schema "exports_exports" do
    field :name, :string
    field :active, :boolean, default: true
    # rename to :type
    field :export_target_type, ExportTargetType

    has_many :export_companies, ExportCompany, on_delete: :delete_all, on_replace: :delete
    has_many :companies, through: [:export_companies, :company], on_delete: :nothig

    has_many :export_jobs, ExportJob, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(export, attrs) do
    export
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:export_companies, with: &ExportCompany.changeset/2)
  end
end
