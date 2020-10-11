defmodule TaskArchitecture.Services.ConvertToFile.ApecTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Model.Export.ApecJobEntity
  alias TaskArchitecture.Services.ConvertToFile.Apec

  @company_params %{
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
  }

  setup do
    company = company_fixture(@company_params)

    valid_companies_jobs = [
      %ApecJobEntity{
        affichage: 1,
        batiment: nil,
        candidature_email: nil,
        candidature_url: "http://apec.com",
        code_naf: "234",
        code_postal: nil,
        complement: nil,
        date_prise_poste: nil,
        duree_contrat: nil,
        enseigne: "enseigne1",
        enterprise:
          "Never say feverNever say feverNever say feverNever say feverNever say feverNever say feverNever say fever",
        experience: 2,
        fonction: nil,
        fonction_complementaire: nil,
        lieu: "123445",
        nombre_poste: 1,
        poste:
          "##Junior konzultant/ka - Business Intelligence\n\nPřidej se k našemu Business Intelligence týmu a pomáhej našim klientům se strategickým řízením jejich podniku pomocí dat. Jsme konzultanti, nečekej tedy, že u nás budeš jen sedět u stolu a vytvářet datové sklady. Velkou část naší práce tvoří komunikace s klientem a s technickými odborníky, kteří implementují námi navržené řešení.\nProjekty, na kterých pracujeme, jsou velmi různorodé, od těch měkčích, jako je podpora řízení dat ve společnosti (Data Governance), po ty tvrdší (návrh a implementace DWH).\n*komunikovat s klientem\n*navrhovat řešení pro velké množství dat\n*pracovat s profesionálními nástroji (SQL, Power BI, Oracle BI, Tableau a další)\n*pomáhat seniornějším kolegům se zpracováním projektových výstupů\n*rozvíjet své IT znalosti a postupně zjišťovat, jakým směrem se chceš profilovat\n*VŠ vzdělání (specializace na IT, BI a DA výhodou)\n*základní znalost SQL\n*orientaci v základních Business Intelligence pojmech (UML, logický a fyzický datový model atd.)\n*dobré komunikační dovednosti\n*plynulou komunikaci v angličtině\n*práci na Florenci v nejlepších kancelářích roku 2019\n*20 000 Kč na sport, cestování a další benefity\n*dalších 30 000 Kč na neziskovku, kterou chceš podpořit\n*150 hodin jógy a tréninků na terase\n*50 hodin angličtiny či němčiny s rodilým mluvčím\n*životní a úrazové pojištění\n*odborná i soft-skills školení a profesní certifikace – např. Princ 2\ncc3\nabsolvent\n## Benefits\n- Mobilní telefon\n- Notebook\n- Příspěvek na penzijní/životní připojištění\n- Flexibilní začátek/konec pracovní doby\n- Stravenky/příspěvek na stravování\n- Dovolená 5 týdnů\n- Vzdělávací kurzy, školení\n- Kafetérie",
        presentation: nil,
        process_recrutement: nil,
        profil:
          "Never say neverNever say neverNever say neverNever say neverNever say neverNever say neverNever say never",
        raison_sociale: "raison_sociale1",
        reference: "Fx3Z6VUoUX",
        rue: nil,
        salaire_max: 50_000,
        salaire_min: 20_000,
        siret: "siret1",
        statut_poste: "CADRE_PRIVE",
        temps_travail: "TEMPS_PLEIN",
        titre: "BA1 - BI Bauer 2FTE H/F",
        type_contrat: 1,
        ville: "Paris",
        zone_deplacement: "AUCUN"
      }
    ]

    {:ok, company: company, valid_companies_jobs: valid_companies_jobs}
  end

  describe "#call" do
    test "Return errors if they will appear. Parse valid job entities", %{
      company: company,
      valid_companies_jobs: valid_companies_jobs
    } do
      {:ok, standard} =
        File.read("./test/fixtures/export/export_to_file_examples/apec/apec_example.xml")

      jobs_list = [{company, valid_companies_jobs}]
      assert {:ok, {success_list, []}} = Apec.call(jobs_list)
      [{_, result}] = success_list
      assert result == standard
    end
  end
end
