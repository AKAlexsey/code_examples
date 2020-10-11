defmodule TaskArchitecture.Services.Export.ExportWorkerTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.{Company, ExportJob}
  alias TaskArchitecture.Exports.CompanyEmbedded.ApecManualFields
  alias TaskArchitecture.Model.ExportReport
  alias TaskArchitecture.Repo
  alias TaskArchitecture.Services.Export.ExportWorker
  alias TaskArchitecture.Services.Export.StorageClient.DevStorage

  describe "#run" do
    setup do
      {:ok, example_content} =
        File.read("#{File.cwd!()}/#{DevStorage.file_folder()}/feed_files_example.xml")

      export =
        export_fixture(%{name: "Export1", export_target_type: "apec"})
        |> Repo.preload([:export_companies, :companies])

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
        export_fixture(%{name: "Export2", export_target_type: "apec"})
        |> Repo.preload([:export_companies, companies: :export_companies])

      file_folder = DevStorage.file_folder()

      on_exit(make_ref(), fn ->
        DevStorage.delete_from_storage(company.organization_reference, export)
        File.rmdir("#{File.cwd!()}/#{file_folder}/#{export.id}")
      end)

      company = Repo.preload(company, [:export_companies])

      {:ok,
       export: export,
       invalid_export: invalid_export,
       company: company,
       example_content: example_content}
    end

    test "Write files to store. Create export_job if all params is valid.", %{
      export: %{id: export_id},
      company: company
    } do
      export = Exports.get_export(export_id, [:export_companies, companies: :export_companies])

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      assert {:ok,
              %ExportReport{
                start_type: "testing",
                export: ^export,
                failed_export: false,
                failed_reasons: _,
                successful_sent: [{^company, "ok"}]
              }} = ExportWorker.run(export, start_type: "testing")

      timeout_assert(fn ->
        before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end

    test "Return invalid report if export does not have companies. Create ExportJob. Does not write files to store. Add fail reason to failed_reasons list",
         %{
           invalid_export: export
         } do
      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      {:ok,
       %ExportReport{
         start_type: "testing",
         export: ^export,
         failed_export: true,
         failed_reasons: [
           {"Fail reason on: get_export_companies", :get_export_companies,
            "Export has no companies"}
         ]
       }} = ExportWorker.run(export, start_type: "testing")

      timeout_assert(fn ->
        assert before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end

    test "Return invalid report if export company invalid. Create ExportJob. Does not write files to store. Add fail reason to failed_reasons list",
         %{
           invalid_export: export
         } do
      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      invalid_company = %Company{
        organization_reference: "ref1",
        access_token: "1",
        apec_manual_fields: %ApecManualFields{
          limitation_rules: "limitation_rules",
          enseigne: "enseigne1",
          raison_sociale: "raison_sociale1",
          siret: "siret1",
          code_naf: "234",
          default_min_salary: 30_000,
          default_max_salary: 40_000,
          default_lieu: "50000"
        }
      }

      export = Map.put(export, :companies, [invalid_company])

      {:ok,
       %ExportReport{
         start_type: "testing",
         export: ^export,
         failed_export: true,
         failed_reasons: [
           {"Fail reason on: get_export_companies", :get_export_companies, "No success results"},
           {"Fail reason on: get_export_companies", :get_export_companies, "Companies invalid"}
         ]
       }} = ExportWorker.run(export, start_type: "testing")

      timeout_assert(fn ->
        assert before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end
  end
end
