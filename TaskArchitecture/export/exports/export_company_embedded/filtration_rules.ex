defmodule TaskArchitecture.Exports.ExportCompanyEmbedded.FiltrationRules do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TaskArchitecture.Exports.ExportCompanyEmbedded.Rule

  @type t :: %__MODULE__{}

  embedded_schema do
    embeds_many :rules, Rule, on_replace: :delete
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [])
    |> cast_embed(:rules, with: &Rule.changeset/2)
  end
end
