defmodule TaskArchitecture.Services.Export.ExportToTargetTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Configurations.Target
  alias TaskArchitecture.Exports.Company
  alias TaskArchitecture.Services.Export.ExportToTarget

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

      {:ok, export: export, company: company}
    end

    test "Return target is company and export are valid", %{
      export: export,
      company: company
    } do
      assert {:ok,
              %Target{
                config: %{
                  access_token: "token",
                  organization_reference: "reference",
                  limitation_rules: "limitation_rules"
                }
              }} = ExportToTarget.perform(company, export)
    end

    test "Return error if company invalid #1", %{export: export} do
      company = %Company{
        organization_reference: "reference"
      }

      assert {:error, "Company does not have organization_reference or access_token"} ==
               ExportToTarget.perform(company, export)
    end

    test "Return error if company invalid #2", %{export: export} do
      company = %Company{
        access_token: "access_token"
      }

      assert {:error, "Company does not have organization_reference or access_token"} ==
               ExportToTarget.perform(company, export)
    end

    test "Return error if params invalid" do
      assert {:error, "Invalid arguments: %{}, %{}"} ==
               ExportToTarget.perform(%{}, %{})
    end
  end
end
