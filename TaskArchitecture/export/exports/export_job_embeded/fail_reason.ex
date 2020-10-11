defmodule TaskArchitecture.Exports.ExportJobEmbeded.FailReason do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TaskArchitecture.Exports.ExportJobEmbeded.StageFailReason

  @type t :: %__MODULE__{}

  embedded_schema do
    embeds_many :stage_fail_reasons, StageFailReason, on_replace: :delete
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [])
    |> cast_embed(:stage_fail_reasons, with: &StageFailReason.changeset/2)
  end
end
