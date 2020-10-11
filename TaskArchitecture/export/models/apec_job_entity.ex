defmodule TaskArchitecture.Model.Export.ApecJobEntity do
  @moduledoc """
  Represents job entity for APEC
  """

  import Ecto.Changeset

  alias TaskArchitecture.Common.Utils

  @type t :: %__MODULE__{}

  defstruct reference: nil,
            titre: nil,
            type_contrat: nil,
            duree_contrat: nil,
            enseigne: nil,
            poste: nil,
            profil: nil,
            enterprise: nil,
            process_recrutement: nil,
            presentation: nil,
            statut_poste: nil,
            nombre_poste: nil,
            temps_travail: nil,
            salaire_min: nil,
            salaire_max: nil,
            affichage: nil,
            fonction: nil,
            fonction_complementaire: nil,
            experience: nil,
            rue: nil,
            code_postal: nil,
            ville: nil,
            batiment: nil,
            complement: nil,
            lieu: nil,
            zone_deplacement: nil,
            candidature_url: nil,
            candidature_email: nil,
            date_prise_poste: nil,
            raison_sociale: nil,
            siret: nil,
            code_naf: nil

  @schema %{
    reference: :string,
    titre: :string,
    type_contrat: :integer,
    duree_contrat: :integer,
    enseigne: :string,
    poste: :string,
    profil: :string,
    enterprise: :string,
    process_recrutement: :string,
    presentation: :string,
    statut_poste: :string,
    nombre_poste: :integer,
    temps_travail: :string,
    salaire_min: :integer,
    salaire_max: :integer,
    affichage: :integer,
    fonction: :string,
    fonction_complementaire: :string,
    experience: :integer,
    rue: :string,
    code_postal: :string,
    ville: :string,
    batiment: :string,
    complement: :string,
    lieu: :string,
    zone_deplacement: :string,
    candidature_url: :string,
    candidature_email: :string,
    date_prise_poste: :string,
    raison_sociale: :string,
    siret: :string,
    code_naf: :string
  }
  @required_fields [
    :reference,
    :titre,
    :type_contrat,
    :poste,
    :profil,
    :enterprise,
    :salaire_min,
    :salaire_max,
    :affichage,
    :lieu,
    :candidature_url,
    :raison_sociale,
    :siret,
    :code_naf
  ]

  @spec new(map) :: {:ok, __MODULE__.t()} | {:error, binary}
  def new(data) when is_map(data), do: from(%__MODULE__{}, data)

  @spec from(__MODULE__.t(), map) :: {:ok, __MODULE__.t()} | {:error, binary}
  def from(%__MODULE__{} = job, data) when is_map(data) do
    job
    |> changeset(data)
    |> case do
      %{valid?: true, changes: valid_params} ->
        {:ok, Map.merge(job, valid_params)}

      %{valid?: false} = invalid_changeset ->
        {:error, Utils.changeset_error_to_string(invalid_changeset)}
    end
  end

  @spec changeset(Ecto.Changeset.t() | __MODULE__.t(), map) :: Ecto.Changeset.t()
  def changeset(job, data) when is_map(data) do
    {job, @schema}
    |> cast(data, Map.keys(@schema))
    |> validate_required(@required_fields)
  end
end
