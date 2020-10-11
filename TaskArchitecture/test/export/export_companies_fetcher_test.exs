defmodule TaskArchitecture.Services.Export.ExportCompaniesFetcherTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Services.Export.ExportCompaniesFetcher

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

      export_company_fixture(%{export_id: export.id, company_id: company.id})

      invalid_export =
        export_fixture(%{name: "Export2", export_target_type: "apec", active: true})

      company = Repo.preload(company, [:export_companies])

      {:ok, export: export, invalid_export: invalid_export, company: company}
    end

    test "Return error if export does not have companies", %{invalid_export: invalid_export} do
      export = Repo.preload(invalid_export, [:export_companies, companies: :export_companies])
      assert {:error, "Export has no companies"} = ExportCompaniesFetcher.call(export)
    end

    test "Return error if companies are not preloaded", %{export: export} do
      assert {:error, "Companies are not preloaded"} = ExportCompaniesFetcher.call(export)
    end

    test "Return valid and invalid companies if they are present", %{
      export: export,
      company: company
    } do
      {:ok, %{company: invalid_company}} =
        Exports.create_export_company_with_company(%{
          company_id: "",
          export_id: export.id,
          organization_reference: "ref2",
          access_token: "1"
        })

      invalid_company =
        invalid_company
        |> Repo.preload([:export_companies])

      export_company_fixture(%{export_id: export.id, company_id: invalid_company.id})
      :timer.sleep(100)

      export =
        export
        |> Repo.preload([:export_companies, companies: :export_companies])

      assert {:ok, {[^company], [{^invalid_company, error_message}]}} =
               ExportCompaniesFetcher.call(export)

      assert error_message ==
               "apec_manual_fields: [code_naf: can't be blank; default_enterprise: can't be blank; default_lieu: can't be blank; default_max_salary: can't be blank; default_min_salary: can't be blank; default_profile: can't be blank; raison_sociale: can't be blank; siret: can't be blank]"
    end
  end
end
