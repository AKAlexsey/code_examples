defmodule TaskArchitecture.Exports.ExportCompanyEmbedded.Rule do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @cast_fields [
    :field,
    :value,
    :operation
  ]
  @required_fields [
    :field,
    :value,
    :operation
  ]
  @allowed_fields [
    "description",
    "profile",
    "language",
    "office_id",
    "remote"
  ]
  @allowed_operations [
    "equal",
    "contains"
  ]

  @type t :: %__MODULE__{}

  embedded_schema do
    field :field, :string, default: Enum.at(@allowed_fields, 0)
    field :value, :string
    field :operation, :string, default: Enum.at(@allowed_operations, 0)
  end

  def allowed_fields, do: @allowed_fields
  def allowed_operations, do: @allowed_operations

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:operation, @allowed_operations)
    |> validate_inclusion(:field, @allowed_fields)
  end
end
