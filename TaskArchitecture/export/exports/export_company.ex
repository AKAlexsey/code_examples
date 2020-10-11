defmodule TaskArchitecture.Exports.ExportCompany do
  @moduledoc false

  @type t :: %__MODULE__{}

  @cast_fields [:company_id, :export_id]
  @required_fields [:company_id, :export_id]

  use Ecto.Schema
  import Ecto.Changeset

  alias TaskArchitecture.Exports.{Company, Export}
  alias TaskArchitecture.Exports.ExportCompanyEmbedded.FiltrationRules

  schema "exports_export_company" do
    belongs_to :company, Company
    belongs_to :export, Export

    embeds_many :filtration_rules, FiltrationRules, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = export_company, attrs) do
    export_company
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:company, with: &Company.changeset/2)
    |> cast_assoc(:export, with: &Export.changeset/2)
    |> unique_constraint(
      [:company_id, :export_id],
      name: :exports_export_company_export_id_company_id_index,
      message: "This relation already exists."
    )
    |> cast_embed(:filtration_rules, witi: &FiltrationRules.changeset/2)
  end
end
