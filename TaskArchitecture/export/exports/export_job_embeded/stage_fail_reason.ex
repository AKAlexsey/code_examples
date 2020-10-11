defmodule TaskArchitecture.Exports.ExportJobEmbeded.StageFailReason do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TaskArchitecture.Changeset.AttrsNormalizer
  alias TaskArchitecture.Exports.ExportJobEmbeded.StageError

  @cast_fields [:title, :message]
  @required_fields [:title, :message]

  @type t :: %__MODULE__{}

  embedded_schema do
    field :title, :string
    field :message, :string
    embeds_many :stage_errors, StageError, on_replace: :delete
  end

  @doc false
  def changeset(company, attrs) do
    normalized_attrs = AttrsNormalizer.normalize(attrs, %{})

    company
    |> cast(normalized_attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:stage_errors, with: &StageError.changeset/2)
  end
end
