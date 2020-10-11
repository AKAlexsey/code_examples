defmodule TaskArchitecture.Services.Export.JobOffersFetcherTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports.Company
  alias TaskArchitecture.Model.WelcomeKitJobEntity
  alias TaskArchitecture.Services.Export.JobOffersFetcher

  describe "#perform" do
    setup do
      export =
        export_fixture(%{
          name: "Export",
          export_target_type: "apec",
          limitation_rules: "limitation_rules"
        })

      company =
        company_fixture(%{
          organization_reference: "reference",
          access_token: "token",
          apec_manual_fields: %{
            limitation_rules: "limitation_rules",
            enseigne: "enseigne1",
            raison_sociale: "raison_sociale1",
            siret: "siret1",
            code_naf: "234",
            default_min_salary: 40_000,
            default_max_salary: 50_000,
            default_profile: String.duplicate("Never say never", 7),
            default_lieu: "50000",
            default_enterprise: String.duplicate("Never say fever", 7)
          }
        })

      invalid_company = %Company{
        organization_reference: "reference"
      }

      {:ok, export: export, company: company, invalid_company: invalid_company}
    end

    test "Fetch records for valid companies and return errors for invalid companies", %{
      export: export,
      company: company,
      invalid_company: invalid_company
    } do
      assert {:ok, {valid_companies, invalid_companies}} =
               JobOffersFetcher.call(
                 [company, invalid_company],
                 [{company, %{}}, {invalid_company, %{}}],
                 export
               )

      assert [{^company, fetched_records}] = valid_companies

      assert Enum.all?(fetched_records, fn %{__struct__: struct} ->
               struct == WelcomeKitJobEntity
             end)

      assert [{^invalid_company, "Company does not have organization_reference or access_token"}] =
               invalid_companies
    end

    test "Return error if given companies list is empty", %{export: export} do
      assert {:error, "No companies configurations given as parameter"} =
               JobOffersFetcher.call([], [], export)
    end
  end
end
