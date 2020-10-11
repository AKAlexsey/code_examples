defmodule TaskArchitecture.Services.ConvertToFile.Apec do
  @moduledoc """
  Convert Platform to Apec specific xml files
  """

  @default_convert_time_timeout 60_000

  alias TaskArchitecture.Common.ExceptionFormatter
  alias TaskArchitecture.Model.Export.ApecJobEntity
  alias TaskArchitecture.Model.PlatformJobEntity

  import XmlBuilder

  @spec call(list(tuple)) :: {:ok, {list(tuple), list(tuple)}} | {:error, binary}
  def call(valid_companies_jobs) do
    Task.async_stream(
      valid_companies_jobs,
      fn {_company, jobs} ->
        Process.flag(:trap_exit, true)
        convert_entities(jobs)
      end,
      timeout: @default_convert_time_timeout,
      on_timeout: :kill_task
    )
    |> Stream.with_index()
    |> Enum.reduce({[], []}, fn
      {{:ok, {:ok, records_xml}}, index}, {success_list, failed_list} ->
        {[{get_company(valid_companies_jobs, index), records_xml}] ++ success_list, failed_list}

      {{:ok, {:error, reason}}, index}, {success_list, failed_list} ->
        {success_list, [{get_company(valid_companies_jobs, index), reason}] ++ failed_list}

      {{:exit, reason}, index}, {success_list, failed_list} ->
        {success_list,
         [
           {get_company(valid_companies_jobs, index),
            ExceptionFormatter.make_error_message(reason)}
         ] ++ failed_list}
    end)
    |> (fn result -> {:ok, result} end).()
  end

  @spec convert_entities(list(PlatformJobEntity.t())) ::
          {:ok, binary, list} | {:error, binary}
  defp convert_entities(jobs) do
    jobs
    |> Enum.map(&convert_entity/1)
    |> Enum.join("\n")
    |> (fn val -> {:ok, val} end).()
  end

  defp convert_entity(%ApecJobEntity{} = job) do
    xml_tag(:offre, [
      xml_tag(:reference, job.reference),
      xml_tag(:titre, job.titre, true),
      xml_tag(:typeContrat, job.type_contrat),
      xml_tag(:dureeContrat, job.duree_contrat),
      xml_tag(:enseigne, job.enseigne, true),
      xml_tag(:texte, [
        xml_tag(:poste, job.poste, true),
        xml_tag(:profil, job.profil, true),
        xml_tag(:entreprise, job.enterprise, true),
        xml_tag(:processRecrutement, job.process_recrutement, true),
        xml_tag(:presentation, job.presentation)
      ]),
      xml_tag(:statutPoste, job.statut_poste),
      xml_tag(:nombrePoste, job.nombre_poste),
      xml_tag(:tempsTravail, job.temps_travail),
      xml_tag(:salaire, [
        xml_tag(:min, job.salaire_min),
        xml_tag(:max, job.salaire_max),
        xml_tag(:affichage, job.affichage)
      ]),
      xml_tag(:fonction, job.fonction),
      xml_tag(:fonctionComplementaire, job.fonction_complementaire),
      xml_tag(:experience, job.experience),
      xml_tag(:adresse, [
        xml_tag(:rue, job.rue, true),
        xml_tag(:codePostal, job.code_postal),
        xml_tag(:ville, job.ville, true),
        xml_tag(:batiment, job.batiment),
        xml_tag(:complement, job.complement)
      ]),
      xml_tag(:lieu, job.lieu),
      xml_tag(:zoneDeplacement, job.zone_deplacement),
      xml_tag(:candidature, [
        xml_tag(:url, job.candidature_url),
        xml_tag(:email, job.candidature_email)
      ]),
      xml_tag(:datePrisePoste, job.date_prise_poste),
      xml_tag(:clientIndirect, [
        xml_tag(:raisonSociale, job.raison_sociale, true),
        xml_tag(:siret, job.siret),
        xml_tag(:codeNaf, job.code_naf)
      ])
    ])
    |> generate()
  end

  defp xml_tag(tag, content, safe \\ false)

  defp xml_tag(tag, content, _safe) when is_list(content) do
    element(tag, %{}, content)
  end

  defp xml_tag(tag, nil, _safe) do
    element(tag, %{}, "")
  end

  defp xml_tag(tag, "", _safe) do
    element(tag, %{}, "")
  end

  defp xml_tag(tag, content, true) do
    element(tag, %{}, protect_special_characters(content))
  end

  defp xml_tag(tag, content, false) do
    element(tag, %{}, content)
  end

  defp protect_special_characters(content) do
    case content do
      binary_content when is_binary(binary_content) ->
        {:cdata, binary_content}

      integer_content when is_integer(integer_content) ->
        "#{integer_content}"

      _ ->
        content
    end
  end

  @spec get_company(list, integer) :: binary
  defp get_company(platform_jobs, index) do
    Enum.at(platform_jobs, index)
    |> (fn {company, _} -> company end).()
  end
end
