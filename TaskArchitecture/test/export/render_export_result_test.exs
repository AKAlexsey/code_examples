defmodule TaskArchitecture.Services.Export.RenderExportResultTest do
  use TaskArchitecture.DataCase, async: false

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Services.Export.RenderExportResult
  alias TaskArchitecture.Services.Export.StorageClient.DevStorage

  @apec_limitation_rules_params %{
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

  describe "#perform" do
    setup do
      export_type = "apec"

      export1 =
        export_fixture(%{
          active: true,
          name: "Export1",
          export_target_type: export_type
        })

      export2 =
        export_fixture(%{
          active: false,
          name: "Export2",
          export_target_type: export_type
        })

      company1 =
        company_fixture(%{
          organization_reference: "reference111111111",
          access_token: "token",
          apec_manual_fields: @apec_limitation_rules_params
        })

      company2 =
        company_fixture(%{
          organization_reference: "reference222222222",
          access_token: "token",
          apec_manual_fields: @apec_limitation_rules_params
        })

      company3 =
        company_fixture(%{
          organization_reference: "reference333333333",
          access_token: "token",
          apec_manual_fields: @apec_limitation_rules_params
        })

      export_company_fixture(%{company_id: company1.id, export_id: export1.id})
      export_company_fixture(%{company_id: company2.id, export_id: export1.id})
      export_company_fixture(%{company_id: company3.id, export_id: export2.id})

      {:ok, content_example_1} =
        File.read("#{File.cwd!()}/test/feed_files/render_result_contents/content_example_1.xml")

      {:ok, content_example_2} =
        File.read("#{File.cwd!()}/test/feed_files/render_result_contents/content_example_2.xml")

      DevStorage.write_to_storage(content_example_1, company1.organization_reference, export1)
      DevStorage.write_to_storage(content_example_2, company2.organization_reference, export1)

      {:ok, standard} = File.read("#{File.cwd!()}/test/feed_files/apec_example.xml")

      on_exit(make_ref(), fn ->
        DevStorage.delete_from_storage(company1.organization_reference, export1)
        DevStorage.delete_from_storage(company2.organization_reference, export1)
        File.rm("#{File.cwd!()}/test/feed_files/apec.xml")
      end)

      {:ok, export_type: export_type, standard: standard, export1: export1, export2: export2}
    end

    test "Compile files into result valid xml", %{
      export_type: export_type,
      standard: standard
    } do
      timeout_assert(fn ->
        {:error, :enoent} = File.read("#{File.cwd!()}/test/feed_files/apec.xml")
      end)

      assert :ok = RenderExportResult.perform(export_type)
      {:ok, written_content} = File.read("#{File.cwd!()}/test/feed_files/apec.xml")

      assert standard == written_content
    end

    test "Return error if export type invalid" do
      export_type = "invalid_type"

      assert {:error, "Invalid export type #{export_type}"} ==
               RenderExportResult.perform(export_type)
    end

    test "Return error if there are no active export types", %{
      export_type: export_type,
      export1: export1
    } do
      Exports.update_export(export1, %{active: false})
      :timer.sleep(100)

      assert {:error, "No active exports"} == RenderExportResult.perform(export_type)
    end

    test "Return :ok, if there are no content for active exports", %{
      export_type: export_type,
      export1: export1,
      export2: export2
    } do
      Exports.update_export(export1, %{active: false})
      Exports.update_export(export2, %{active: true})
      :timer.sleep(100)

      assert :ok = RenderExportResult.perform(export_type)
    end
  end
end
