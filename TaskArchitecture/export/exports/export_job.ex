defmodule TaskArchitecture.Exports.ExportJob do
  @moduledoc false

  @type t :: %__MODULE__{}

  use Ecto.Schema
  import Ecto.Changeset
  alias TaskArchitecture.Exports.Export
  alias TaskArchitecture.Exports.ExportJobEmbeded.FailReason

  @cast_fields [
    :datetime,
    :successful,
    :exported_count,
    :filtered_count,
    :failed_count,
    :companies_count,
    :success_companies_count,
    :type,
    :export_id,
    :start_type
  ]
  @required_fields [
    :datetime,
    :successful,
    :exported_count,
    :filtered_count,
    :failed_count,
    :companies_count,
    :success_companies_count,
    :type,
    :export_id,
    :start_type
  ]

  schema "exports_export_jobs" do
    field :datetime, :naive_datetime
    field :exported_count, :integer
    field :failed_count, :integer, default: 0
    field :filtered_count, :integer, default: 0
    field :successful, :boolean, default: false
    field :start_type, :string
    field :type, ExportTargetType
    field :companies_count, :integer
    field :success_companies_count, :integer

    embeds_one :fail_reason, FailReason, on_replace: :update
    belongs_to :export, Export

    timestamps()
  end

  @doc false
  def changeset(export_job, attrs) do
    export_job
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:fail_reason, with: &FailReason.changeset/2)
  end
end
