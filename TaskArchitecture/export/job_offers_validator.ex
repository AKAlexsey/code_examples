defmodule TaskArchitecture.Services.Export.JobOffersValidator do
  @moduledoc """
  Concurrently fetch job offers according to the configurations given as peremeter
  """

  @title_required_postfix "H/F"
  @maximum_title_length 76

  @contract_type_mapping %{
    "FULL_TIME" => 1,
    "TEMPORARY" => 5,
    "APPRENTICESHIP" => 7
  }

  @experience_level_mapping %{
    "LESS_THAN_6_MONTHS" => 1,
    "6_MONTHS_TO_1_YEAR" => 1,
    "1_TO_2_YEARS" => 3,
    "2_TO_3_YEARS" => 4,
    "3_TO_4_YEARS" => 5,
    "4_TO_5_YEARS" => 6,
    "5_TO_7_YEARS" => 7,
    "7_TO_10_YEARS" => 9,
    "10_TO_15_YEARS" => 12,
    "MORE_THAN_15_YEARS" => 12
  }
  @default_experience_level 2

  alias TaskArchitecture.Exports.Company
  alias TaskArchitecture.Exports.CompanyEmbedded.ApecManualFields
  alias TaskArchitecture.Model.Export.ApecJobEntity
  alias TaskArchitecture.Model.PlatformJobEntity

  @spec call(list(tuple)) :: {:ok, {list(tuple), list(tuple)}} | {:error, binary}
  def call([]), do: {:error, "Job offers are given"}

  def call(filtered_by_limitations) do
    filtered_by_limitations
    |> Enum.reduce({[], []}, fn {company, jobs}, {success, failed} ->
      validate_jobs(jobs, company)
      |> (fn
            {[], failed_jobs} ->
              {success, failed_jobs ++ failed}

            {success_apec_jobs, failed_jobs} ->
              {[{company, success_apec_jobs}] ++ success, failed_jobs ++ failed}
          end).()
    end)
    |> (fn result -> {:ok, result} end).()
  end

  defp validate_jobs(jobs, company) do
    jobs
    |> Enum.reduce({[], []}, fn job, {success, failed} ->
      job
      |> get_entity_params(company)
      |> case do
        {:ok, apec_job_entity} ->
          {[apec_job_entity] ++ success, failed}

        {:error, reason} ->
          {success, [{job, reason}] ++ failed}
      end
    end)
  end

  @spec get_entity_params(PlatformJobEntity, Company) :: {:ok, ApecJobEntity} | {:error, binary}
  def get_entity_params(%PlatformJobEntity{} = job, %Company{
        apec_manual_fields: apec_manual_fields
      }) do
    %{
      enseigne: enseigne,
      raison_sociale: raison_sociale,
      siret: siret,
      code_naf: code_naf,
      default_min_salary: default_min_salary,
      default_max_salary: default_max_salary,
      default_profile: default_profile,
      default_lieu: default_lieu,
      default_enterprise: default_enterprise
    } = safe_get_manual_fields(apec_manual_fields)

    %{
      reference: reference,
      name: name,
      contract_duration_min: contract_duration_min,
      contract_type: contract_type,
      experience_level: experience_level,
      description: description,
      profile: profile,
      company_description: company_description,
      recruitment_process: recruitment_process,
      salary_min: salary_min,
      salary_max: salary_max,
      apply_url: apply_url,
      office_address: office_address,
      office_zip_code: office_zip_code,
      office_city: office_city,
      start_date: start_date
    } = job

    profile_value = get_profile(profile, default_profile)

    %{
      reference: reference,
      titre: complement_name(name),
      type_contrat: get_contract_type(contract_type),
      duree_contrat: contract_duration_min,
      enseigne: enseigne,
      poste: description,
      profil: profile_value,
      enterprise: value_or_default(company_description, default_enterprise),
      process_recrutement: recruitment_process,
      presentation: nil,
      statut_poste: "CADRE_PRIVE",
      nombre_poste: 1,
      temps_travail: "TEMPS_PLEIN",
      salaire_min: value_or_default(salary_min, default_min_salary),
      salaire_max: value_or_default(salary_max, default_max_salary),
      affichage: get_affichage(salary_min, salary_max),
      fonction: nil,
      fonction_complementaire: nil,
      experience: get_experience(experience_level),
      rue: office_address,
      code_postal: office_zip_code,
      ville: office_city,
      batiment: nil,
      complement: nil,
      lieu: value_or_default(office_zip_code, default_lieu),
      zone_deplacement: "AUCUN",
      candidature_url: apply_url,
      candidature_email: nil,
      date_prise_poste: start_date,
      raison_sociale: raison_sociale,
      siret: siret,
      code_naf: code_naf
    }
    |> ApecJobEntity.new()
  end

  defp safe_get_manual_fields(nil) do
    %{
      enseigne: nil,
      raison_sociale: nil,
      siret: nil,
      code_naf: nil,
      default_min_salary: nil,
      default_max_salary: nil,
      default_profile: nil,
      default_lieu: nil,
      default_enterprise: nil
    }
  end

  defp safe_get_manual_fields(apec_manual_fields), do: apec_manual_fields

  defp get_profile(profile, default_profile) do
    case profile do
      nil ->
        default_profile

      "" ->
        default_profile

      profile_string ->
        if String.length(profile_string) < ApecManualFields.profile_min_length() do
          default_profile
        else
          profile_string
        end
    end
  end

  defp complement_name(name) when is_binary(name) do
    if String.contains?(name, @title_required_postfix) do
      name
    else
      if String.length(name) < @maximum_title_length do
        "#{name} #{@title_required_postfix}"
      else
        name
        |> String.split(" ")
        |> Enum.reduce_while("", fn word, result_string ->
          str = result_string <> word <> " "

          if String.length(str) < @maximum_title_length + 1 do
            {:cont, str}
          else
            {:halt, result_string <> @title_required_postfix}
          end
        end)
      end
    end
  end

  defp complement_name(name), do: name

  defp value_or_default("", default), do: default
  defp value_or_default(nil, default), do: default
  defp value_or_default(value, _default), do: value

  defp get_affichage(salary_min, nil) when is_number(salary_min), do: 1

  defp get_affichage(salary_min, salary_max) when is_number(salary_min) and is_number(salary_max),
    do: 2

  defp get_affichage(_, _), do: 3

  defp get_contract_type(contract_type) do
    Map.get(@contract_type_mapping, contract_type)
  end

  defp get_experience(experience_level) do
    Map.get(@experience_level_mapping, experience_level, @default_experience_level)
  end
end
