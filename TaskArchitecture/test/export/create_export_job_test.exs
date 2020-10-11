defmodule TaskArchitecture.Services.Export.CreateExportJobTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports.ExportJob
  alias TaskArchitecture.Model.ExportReport
  alias TaskArchitecture.Repo
  alias TaskArchitecture.Services.Export.CreateExportJob

  describe "#perform" do
    setup do
      export = export_fixture(%{name: "Export", export_target_type: "apec"})

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

      export_company_fixture(%{company_id: company.id, export_id: export.id})
      export = export |> Repo.preload([:export_companies, :companies])
      report = %ExportReport{export: export, start_type: "manual"}
      {:ok, export: export, report: report}
    end

    test "Create export report with appropriate parameters if params is valid", %{
      export: export
    } do
      %{id: export_id, export_target_type: type} = export

      report = %ExportReport{
        export: export,
        start_type: "manual",
        failed_export: false,
        companies_jobs: [
          one: [1, 2, 3, 4],
          two: [5, 6, 7, 8]
        ],
        filtered_by_limitations: [
          one: [1, 2, 3],
          two: [5, 6, 7, 8]
        ]
      }

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      datetime = NaiveDateTime.utc_now()

      assert {:ok, result} = CreateExportJob.perform(report, datetime)

      ej_datetime = NaiveDateTime.truncate(datetime, :second)

      assert %ExportJob{
               datetime: ^ej_datetime,
               successful: true,
               exported_count: 0,
               failed_count: 7,
               filtered_count: 1,
               export_id: ^export_id,
               type: ^type
             } = result

      timeout_assert(fn ->
        assert before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end

    test "Return changeset error if some required fields in report are missing #1", %{
      report: report
    } do
      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      datetime = NaiveDateTime.utc_now()

      assert {:error, changeset} =
               CreateExportJob.perform(Map.put(report, :failed_export, nil), datetime)

      assert changeset_has_error?(changeset, :successful)

      assert before_export_report_count == Repo.aggregate(ExportJob, :count, :id)
    end

    test "Return changeset error if some required fields in report are missing #2", %{
      report: report,
      export: export
    } do
      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      datetime = NaiveDateTime.utc_now()

      assert {:error, changeset} =
               CreateExportJob.perform(Map.put(report, :export, %{id: export.id}), datetime)

      assert changeset_has_error?(changeset, :type)

      assert before_export_report_count == Repo.aggregate(ExportJob, :count, :id)
    end

    test "Return changeset error if some required fields in report are missing #3", %{
      report: report
    } do
      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      datetime = NaiveDateTime.utc_now()

      assert {:error, changeset} =
               CreateExportJob.perform(
                 Map.put(report, :export, %{export_target_type: "apec"}),
                 datetime
               )

      assert changeset_has_error?(changeset, :export_id)

      assert before_export_report_count == Repo.aggregate(ExportJob, :count, :id)
    end

    test "Return error if params invalid" do
      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      report = %ExportReport{}
      datetime = DateTime.utc_now()
      assert {:error, "Invalid parameters"} == CreateExportJob.perform(report, datetime)

      assert before_export_report_count == Repo.aggregate(ExportJob, :count, :id)
    end
  end
end
