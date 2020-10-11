defmodule TaskArchitecture.Services.Export.ExportFilterTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports.ExportCompany
  alias TaskArchitecture.Exports.ExportCompanyEmbedded.FiltrationRules
  alias TaskArchitecture.Model.WelcomeKitJobEntity
  alias TaskArchitecture.Repo
  alias TaskArchitecture.Services.Export.ExportFilter

  describe "#perform" do
    setup :preset_job_entities

    setup opts do
      company =
        company_fixture(%{
          organization_reference: "ref1",
          access_token: "token1",
          apec_manual_fields: %{
            enseigne: "enseigne1",
            raison_sociale: "raison_sociale1",
            siret: "siret1",
            code_naf: "234",
            default_min_salary: 40_000,
            default_max_salary: 50_000,
            default_profile: String.duplicate("Never say never", 7),
            default_lieu: "123445",
            default_enterprise: String.duplicate("Never say fever", 7)
          }
        })

      %{jobs_list: jobs_list} = opts

      {
        :ok,
        company: company, jobs_list: jobs_list
      }
    end

    test "Filter jobs that matches given filtration rules", %{
      jobs_list: jobs_list,
      company: company
    } do
      export1 =
        export_fixture(%{
          name: "Export1",
          export_target_type: "apec"
        })

      export2 =
        export_fixture(%{
          name: "Export2",
          export_target_type: "apec"
        })

      export3 =
        export_fixture(%{
          name: "Export3",
          export_target_type: "apec"
        })

      export4 =
        export_fixture(%{
          name: "Export4",
          export_target_type: "apec"
        })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export1.id,
        filtration_rules: [%{rules: [%{field: "remote", value: "true"}]}]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export2.id,
        filtration_rules: [%{rules: [%{field: "profile", value: "4_TO_5_YEARS"}]}]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export3.id,
        filtration_rules: [
          %{
            rules: [
              %{field: "language", value: "en"},
              %{field: "profile", value: "1_TO_2_YEARS"}
            ]
          }
        ]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export4.id,
        filtration_rules: [
          %{
            rules: [
              %{field: "language", value: "en"},
              %{field: "profile", value: "1_TO_2_YEARS"}
            ]
          },
          %{
            rules: [
              %{field: "language", value: "fr"},
              %{field: "remote", value: "true"}
            ]
          }
        ]
      })

      :timer.sleep(100)

      companies_jobs_list = [{Repo.preload(company, [:export_companies]), jobs_list}]

      result1 = ExportFilter.perform(companies_jobs_list, export1)
      assert jobs_has_references?(result1, ["JITA_1", "JITA_5"])

      result2 = ExportFilter.perform(companies_jobs_list, export2)
      assert jobs_has_references?(result2, ["JITA_1", "JITA_2"])

      result3 = ExportFilter.perform(companies_jobs_list, export3)
      assert jobs_has_references?(result3, ["JITA_3"])

      result4 = ExportFilter.perform(companies_jobs_list, export4)
      assert jobs_has_references?(result4, ["JITA_3", "JITA_5"])
    end

    test "Left all jobs if there are no filtration rules", %{
      jobs_list: jobs_list,
      company: company
    } do
      export5 =
        export_fixture(%{
          name: "Export5",
          export_target_type: "apec"
        })

      export6 =
        export_fixture(%{
          name: "Export6",
          export_target_type: "apec"
        })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export5.id,
        filtration_rules: [%{rules: []}]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export6.id
      })

      :timer.sleep(100)

      companies_jobs_list = [{Repo.preload(company, [:export_companies]), jobs_list}]

      result5 = ExportFilter.perform(companies_jobs_list, export5)
      assert jobs_has_references?(result5, ["JITA_1", "JITA_2", "JITA_3", "JITA_4", "JITA_5"])

      result6 = ExportFilter.perform(companies_jobs_list, export6)
      assert jobs_has_references?(result6, ["JITA_1", "JITA_2", "JITA_3", "JITA_4", "JITA_5"])
    end

    test "Apply filtration to all given jobs for all companies", %{
      jobs_list: jobs_list,
      company: company
    } do
      export1 =
        export_fixture(%{
          name: "Export1",
          export_target_type: "apec"
        })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export1.id,
        filtration_rules: [%{rules: [%{field: "remote", value: "true"}]}]
      })

      :timer.sleep(100)

      company = Repo.preload(company, [:export_companies])
      companies_jobs_list = [{company, jobs_list}, {company, jobs_list}]

      [first_result, second_result] = ExportFilter.perform(companies_jobs_list, export1)

      assert jobs_count([first_result]) == 2
      assert jobs_count([second_result]) == 2
    end

    test "Return empty list if not jobs match requirements", %{
      jobs_list: jobs_list,
      company: company
    } do
      export7 =
        export_fixture(%{
          name: "Export7",
          export_target_type: "apec"
        })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export7.id,
        filtration_rules: [
          %{
            rules: [
              %{field: "remote", value: "APPRENTICESHIP"}
            ]
          }
        ]
      })

      :timer.sleep(100)

      company = Repo.preload(company, [:export_companies])
      companies_jobs_list = [{company, jobs_list}]

      assert [] = ExportFilter.perform(companies_jobs_list, export7)
    end

    test "Match filtration partially", %{
      jobs_list: jobs_list,
      company: company
    } do
      export8 =
        export_fixture(%{
          name: "Export8",
          export_target_type: "apec"
        })

      export9 =
        export_fixture(%{
          name: "Export9",
          export_target_type: "apec"
        })

      export10 =
        export_fixture(%{
          name: "Export10",
          export_target_type: "apec"
        })

      export11 =
        export_fixture(%{
          name: "Export11",
          export_target_type: "apec"
        })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export8.id,
        filtration_rules: [
          %{rules: [%{field: "description", value: "developer", operation: "contains"}]}
        ]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export9.id,
        filtration_rules: [
          %{rules: [%{field: "profile", value: "4_TO_5", operation: "contains"}]}
        ]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export10.id,
        filtration_rules: [
          %{
            rules: [
              %{field: "language", value: "fr", operation: "contains"},
              %{field: "profile", value: "1_TO_2", operation: "contains"}
            ]
          }
        ]
      })

      export_company_fixture(%{
        company_id: company.id,
        export_id: export11.id,
        filtration_rules: [
          %{
            rules: [
              %{field: "language", value: "fr", operation: "contains"},
              %{field: "profile", value: "1_TO_2", operation: "contains"}
            ]
          },
          %{
            rules: [
              %{field: "language", value: "en", operation: "contains"}
            ]
          },
          %{
            rules: [
              %{field: "language", value: "es", operation: "contains"}
            ]
          }
        ]
      })

      :timer.sleep(100)

      companies_jobs_list = [{Repo.preload(company, [:export_companies]), jobs_list}]

      result8 = ExportFilter.perform(companies_jobs_list, export8)
      assert jobs_has_references?(result8, ["JITA_2", "JITA_3", "JITA_4", "JITA_5"])

      result9 = ExportFilter.perform(companies_jobs_list, export9)
      assert jobs_has_references?(result9, ["JITA_1", "JITA_2"])

      result10 = ExportFilter.perform(companies_jobs_list, export10)
      assert jobs_has_references?(result10, ["JITA_4", "JITA_5"])

      result11 = ExportFilter.perform(companies_jobs_list, export11)
      assert jobs_has_references?(result11, ["JITA_1", "JITA_2", "JITA_3", "JITA_4", "JITA_5"])
    end

    test "Raise error if rule operation type is unknown", %{
      jobs_list: jobs_list,
      company: company
    } do
      export =
        export_fixture(%{
          name: "Export8",
          export_target_type: "apec"
        })

      export_company = %ExportCompany{
        company_id: company.id,
        export_id: export.id,
        filtration_rules: [
          %FiltrationRules{
            rules: [
              %{field: "language", value: "en", operation: "transfer_to_bank_account"}
            ]
          }
        ]
      }

      company = Map.put(company, :export_companies, [export_company])

      companies_jobs_list = [{company, jobs_list}]

      assert_raise(RuntimeError, "Unknown operation type transfer_to_bank_account", fn ->
        ExportFilter.perform(companies_jobs_list, export)
      end)
    end
  end

  def preset_job_entities(_opts) do
    jobs_list = [
      %WelcomeKitJobEntity{
        external_reference: "digital-recruiter-data-source-the_organization-ZEKQ387",
        archived_at: nil,
        contract_duration_min: 1,
        status: "published",
        salary_min: nil,
        office_country_code: "FR",
        department_id: nil,
        description: "regular office manager",
        language: "es",
        published_at: nil,
        recruitment_process: nil,
        profession_reference: "others_tech",
        reference: "JITA_1",
        apply_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        errors: nil,
        salary_period: nil,
        name: "Office Manager (H/F)",
        experience_level: "4_TO_5_YEARS",
        office_address: "23 Rue d'Aumale",
        salary_currency: nil,
        profile: "4_TO_5_YEARS",
        created_at: nil,
        contract_duration_max: 10,
        remote: true,
        contract_type: "FULL_TIME",
        valid: true,
        cms_sites_references: nil,
        organization_reference: "the_organization",
        salary_max: nil,
        office_id: nil,
        office_zip_code: "75009",
        office_city: "Paris",
        updated_at: nil,
        company_description: "Voici la description de l'entreprise",
        education_level: "BAC_2",
        start_date: nil,
        touched_during_import: false
      },
      %WelcomeKitJobEntity{
        external_reference: "digital-recruiter-data-source-the_organization-ZEKQ387",
        archived_at: nil,
        contract_duration_min: 1,
        status: "published",
        salary_min: nil,
        office_country_code: "FR",
        department_id: nil,
        description: "regular developer",
        language: "en",
        published_at: nil,
        recruitment_process: nil,
        profession_reference: "others_tech",
        reference: "JITA_2",
        apply_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        errors: nil,
        salary_period: nil,
        name: "Web Developer",
        experience_level: "4_TO_5_YEARS",
        office_address: "23 Rue d'Aumale",
        salary_currency: nil,
        profile: "4_TO_5_YEARS",
        created_at: nil,
        contract_duration_max: 10,
        remote: nil,
        contract_type: "TEMPORARY",
        valid: true,
        cms_sites_references: nil,
        organization_reference: "the_organization",
        salary_max: nil,
        office_id: nil,
        office_zip_code: "75009",
        office_city: "Leon",
        updated_at: nil,
        company_description: "Voici la description de l'entreprise",
        education_level: "BAC_2",
        start_date: nil,
        touched_during_import: false
      },
      %WelcomeKitJobEntity{
        external_reference: "digital-recruiter-data-source-the_organization-ZEKQ387",
        archived_at: nil,
        contract_duration_min: 1,
        status: "published",
        salary_min: nil,
        office_country_code: "FR",
        department_id: nil,
        description: "regular developer with dev ops skills",
        language: "en",
        published_at: nil,
        recruitment_process: nil,
        profession_reference: "others_tech",
        reference: "JITA_3",
        apply_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        errors: nil,
        salary_period: nil,
        name: "Web Developer",
        experience_level: "1_TO_2_YEARS",
        office_address: "23 Rue d'Aumale",
        salary_currency: nil,
        profile: "1_TO_2_YEARS",
        created_at: nil,
        contract_duration_max: 10,
        remote: nil,
        contract_type: "TEMPORARY",
        valid: true,
        cms_sites_references: nil,
        organization_reference: "the_organization",
        salary_max: nil,
        office_id: nil,
        office_zip_code: "75009",
        office_city: "Leon",
        updated_at: nil,
        company_description: "Voici la description de l'entreprise",
        education_level: "BAC_2",
        start_date: nil,
        touched_during_import: false
      },
      %WelcomeKitJobEntity{
        external_reference: "digital-recruiter-data-source-the_organization-ZEKQ387",
        archived_at: nil,
        contract_duration_min: 1,
        status: "published",
        salary_min: nil,
        office_country_code: "FR",
        department_id: nil,
        description: "regular frontend developer",
        language: "fr",
        published_at: nil,
        recruitment_process: nil,
        profession_reference: "others_tech",
        reference: "JITA_4",
        apply_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        errors: nil,
        salary_period: nil,
        name: "Frontend Developer",
        experience_level: "1_TO_2_YEARS",
        office_address: "23 Rue d'Aumale",
        salary_currency: nil,
        profile: "1_TO_2_YEARS",
        created_at: nil,
        contract_duration_max: 10,
        remote: nil,
        contract_type: "TEMPORARY",
        valid: true,
        cms_sites_references: nil,
        organization_reference: "the_organization",
        salary_max: nil,
        office_id: nil,
        office_zip_code: "75009",
        office_city: "Paris",
        updated_at: nil,
        company_description: "Voici la description de l'entreprise",
        education_level: "BAC_2",
        start_date: nil,
        touched_during_import: false
      },
      %WelcomeKitJobEntity{
        external_reference: "digital-recruiter-data-source-the_organization-ZEKQ387",
        archived_at: nil,
        contract_duration_min: 1,
        status: "published",
        salary_min: nil,
        office_country_code: "FR",
        department_id: nil,
        description: "irregular developer",
        language: "fr",
        published_at: nil,
        recruitment_process: nil,
        profession_reference: "others_tech",
        reference: "JITA_5",
        apply_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        errors: nil,
        salary_period: nil,
        name: "Frontend Developer",
        experience_level: "1_TO_2_YEARS",
        office_address: "23 Rue d'Aumale",
        salary_currency: nil,
        profile: "1_TO_2_YEARS",
        created_at: nil,
        contract_duration_max: 10,
        remote: true,
        contract_type: "FULL_TIME",
        valid: true,
        cms_sites_references: nil,
        organization_reference: "the_organization",
        salary_max: nil,
        office_id: nil,
        office_zip_code: "75009",
        office_city: "Paris",
        updated_at: nil,
        company_description: "Voici la description de l'entreprise",
        education_level: "BAC_2",
        start_date: nil,
        touched_during_import: false
      }
    ]

    {:ok, jobs_list: jobs_list}
  end

  defp jobs_count([{_, jobs}]) do
    length(jobs)
  end

  defp jobs_has_references?([{_, jobs}], required_references) do
    Enum.all?(jobs, fn %{reference: reference} -> reference in required_references end) and
      length(jobs) == length(required_references)
  end
end
