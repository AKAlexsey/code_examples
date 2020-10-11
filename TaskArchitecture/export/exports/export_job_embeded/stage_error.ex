defmodule TaskArchitecture.Exports.ExportJobEmbeded.StageError do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TaskArchitecture.Changeset.AttrsNormalizer

  @cast_fields [:entity, :message]
  @required_fields [:entity, :message]

  @type t :: %__MODULE__{}

  embedded_schema do
    field :entity, :string
    field :message, :string
  end

  @doc false
  def changeset(company, attrs) do
    normalized_attrs = AttrsNormalizer.normalize(attrs, %{})

    company
    |> cast(normalized_attrs, @cast_fields)
    |> validate_required(@required_fields)
  end
end
