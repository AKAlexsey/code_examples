defmodule TaskArchitecture.Services.Export.JobOffersValidatorTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Model.Export.ApecJobEntity
  alias TaskArchitecture.Model.WelcomeKitJobEntity
  alias TaskArchitecture.Services.Export.JobOffersValidator

  describe "#call" do
    setup do
      export = export_fixture(%{name: "Export1", export_target_type: "apec", active: true})

      company =
        company_fixture(%{
          organization_reference: "ref1",
          access_token: "1",
          apec_manual_fields: %{
            limitation_rules: "limitation_rules",
            enseigne: "enseigne1",
            raison_sociale: "raison_sociale1",
            siret: "siret1",
            code_naf: "234",
            default_min_salary: 30_000,
            default_max_salary: 40_000,
            default_profile: String.duplicate("asc ", 26),
            default_lieu: "50000",
            default_enterprise: String.duplicate("Never say fever", 7)
          }
        })

      {:ok, %{company: invalid_company}} =
        Exports.create_export_company_with_company(%{
          company_id: "",
          export_id: export.id,
          organization_reference: "ref2",
          access_token: "1"
        })

      invalid_job_entity = %WelcomeKitJobEntity{
        apply_url: nil,
        language: nil,
        company_description: nil,
        external_reference: nil,
        salary_period: nil,
        profession_reference: nil,
        status: nil,
        contract_type: nil,
        organization_reference: nil,
        education_level: nil,
        office_zip_code: nil,
        errors: nil,
        valid: nil,
        salary_min: nil,
        office_country_code: nil,
        description: nil,
        contract_duration_min: nil,
        office_id: nil,
        touched_during_import: nil,
        name: nil,
        profile: nil,
        salary_max: nil,
        office_city: nil,
        experience_level: nil,
        remote: nil,
        recruitment_process: nil,
        reference: nil,
        cms_sites_references: nil,
        salary_currency: nil,
        start_date: nil,
        department_id: nil,
        contract_duration_max: nil,
        office_address: nil
      }

      valid_job_entity = %WelcomeKitJobEntity{
        external_reference: "digital-recruiter-data-source-the_organization-ZEKQ387",
        archived_at: nil,
        contract_duration_min: 1,
        status: "published",
        salary_min: nil,
        office_country_code: "FR",
        department_id: nil,
        description:
          "<p>L&apos;Office Manager, est rattaché au VP Sales &amp; Marketing EMEA,. et est   responsable de la préparation des états comptables et financier, de la supervision de la gestion de la paie et du personnel, des achats, de la gestion des comptes fournisseurs et de la gestion du bureau.  Support  également  de l’équipe locale et EMEA, et en support du marketing.</p><p><b>Vos missions :</b></p><ul><li>Gestion des appels téléphoniques; transférer les appels des partenaires, revendeurs, utilisateurs finaux;</li><li>Gérer le classement, le stockage et la sécurité des documents;</li><li>Commander des fournitures (papeterie et d&apos;équipement)</li><li>Gérer la maintenance des locaux, des ordinateurs, des imprimantes et autres équipements de bureau;</li><li>Renouvellements annuels des contrats (assurance médicale, automobile.....);</li><li>Comptabilité: Traitement et paiement des factures, rapprochements des relevés bancaires; préparation des pièces comptable pour le cabinet.</li><li>Support RH :  préparatifs des éléments de paie mensuel , déclaration des effectifs, enregistrement des vacances / congés, l&apos;enregistrement de la maladie et les projets sur demande.</li><li>Préparation des audits annuels;</li><li>Soutenir administrativement l&apos;équipe locale et EMEA</li><li>Support Marketing: organisation d&apos;événements, assistance à la traduction de supports marketing.... </li></ul>",
        language: "fr",
        published_at: nil,
        recruitment_process: nil,
        profession_reference: "others_tech",
        reference: "JITA_osijdf",
        apply_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        errors: nil,
        salary_period: nil,
        name: "Office Manager (H/F)",
        experience_level: "4_TO_5_YEARS",
        office_address: "23 Rue d'Aumale",
        salary_currency: nil,
        profile:
          "<ul><li>Expérience très confirmée sur une fonction polyvalente similaire en tant qu&apos;office manager.</li><li>Maîtrise impérative de l&apos;anglais (bilingue).</li><li>Connaissance des bases de la comptabilité, et de la paie.</li><li>Très forte organisation et rigueur, capacité à gérer plusieurs projets en même temps ; et à maintenir la stricte confidentialité des informations en sa possession.</li><li>Compétences assurées en communication écrite.  </li></ul><h2>Compétences</h2><ul><li>Curiosité</li><li>Proactivité</li><li>Autonomie</li><li>Organisation</li></ul>",
        created_at: nil,
        contract_duration_max: 10,
        remote: nil,
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

      converted_standard = %ApecJobEntity{
        affichage: 3,
        batiment: nil,
        candidature_email: nil,
        candidature_url:
          "https://onrecrutemycompany.integration.srv-ext.com/fr/annonce/879775-office-manager-hf-75009-paris?s_o=wttj#declareStep1",
        code_naf: "234",
        code_postal: "75009",
        complement: nil,
        date_prise_poste: nil,
        duree_contrat: 1,
        enseigne: "enseigne1",
        enterprise: "Voici la description de l'entreprise",
        experience: 6,
        fonction: nil,
        fonction_complementaire: nil,
        lieu: "75009",
        nombre_poste: 1,
        poste:
          "<p>L&apos;Office Manager, est rattaché au VP Sales &amp; Marketing EMEA,. et est   responsable de la préparation des états comptables et financier, de la supervision de la gestion de la paie et du personnel, des achats, de la gestion des comptes fournisseurs et de la gestion du bureau.  Support  également  de l’équipe locale et EMEA, et en support du marketing.</p><p><b>Vos missions :</b></p><ul><li>Gestion des appels téléphoniques; transférer les appels des partenaires, revendeurs, utilisateurs finaux;</li><li>Gérer le classement, le stockage et la sécurité des documents;</li><li>Commander des fournitures (papeterie et d&apos;équipement)</li><li>Gérer la maintenance des locaux, des ordinateurs, des imprimantes et autres équipements de bureau;</li><li>Renouvellements annuels des contrats (assurance médicale, automobile.....);</li><li>Comptabilité: Traitement et paiement des factures, rapprochements des relevés bancaires; préparation des pièces comptable pour le cabinet.</li><li>Support RH :  préparatifs des éléments de paie mensuel , déclaration des effectifs, enregistrement des vacances / congés, l&apos;enregistrement de la maladie et les projets sur demande.</li><li>Préparation des audits annuels;</li><li>Soutenir administrativement l&apos;équipe locale et EMEA</li><li>Support Marketing: organisation d&apos;événements, assistance à la traduction de supports marketing.... </li></ul>",
        presentation: nil,
        process_recrutement: nil,
        profil:
          "<ul><li>Expérience très confirmée sur une fonction polyvalente similaire en tant qu&apos;office manager.</li><li>Maîtrise impérative de l&apos;anglais (bilingue).</li><li>Connaissance des bases de la comptabilité, et de la paie.</li><li>Très forte organisation et rigueur, capacité à gérer plusieurs projets en même temps ; et à maintenir la stricte confidentialité des informations en sa possession.</li><li>Compétences assurées en communication écrite.  </li></ul><h2>Compétences</h2><ul><li>Curiosité</li><li>Proactivité</li><li>Autonomie</li><li>Organisation</li></ul>",
        raison_sociale: "raison_sociale1",
        reference: "JITA_osijdf",
        rue: "23 Rue d'Aumale",
        salaire_max: 40_000,
        salaire_min: 30_000,
        siret: "siret1",
        statut_poste: "CADRE_PRIVE",
        temps_travail: "TEMPS_PLEIN",
        titre: "Office Manager (H/F)",
        type_contrat: 1,
        ville: "Paris",
        zone_deplacement: "AUCUN"
      }

      {:ok,
       invalid_job_entity: invalid_job_entity,
       valid_job_entity: valid_job_entity,
       company: company,
       invalid_company: invalid_company,
       converted_standard: converted_standard}
    end

    test "Return error if there are no job offers." do
      assert {:error, "Job offers are given"} = JobOffersValidator.call([])
    end

    test "Return valid jobs only if both jobs and companies are valid. Convert them.", %{
      company: company,
      invalid_company: invalid_company,
      invalid_job_entity: invalid_job_entity,
      valid_job_entity: valid_job_entity,
      converted_standard: converted_standard
    } do
      assert {:ok, {valid_result, invalid_result}} =
               JobOffersValidator.call([
                 {company, [invalid_job_entity]},
                 {invalid_company, [valid_job_entity]},
                 {company, [valid_job_entity]}
               ])

      assert [{^company, [^converted_standard]}] = valid_result

      assert [
               {^valid_job_entity,
                "code_naf: can't be blank; raison_sociale: can't be blank; salaire_max: can't be blank; salaire_min: can't be blank; siret: can't be blank"},
               {^invalid_job_entity,
                "candidature_url: can't be blank; poste: can't be blank; reference: can't be blank; titre: can't be blank; type_contrat: can't be blank"}
             ] = invalid_result
    end
  end
end
