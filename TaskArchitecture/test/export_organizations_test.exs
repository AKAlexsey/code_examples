defmodule TaskArchitecture.Services.ExportOrganizationsTest do
  use TaskArchitecture.DataCase, async: false
  import ExUnit.CaptureLog

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.{Company, ExportJob}
  alias TaskArchitecture.Exports.CompanyEmbedded.ApecManualFields
  alias TaskArchitecture.Model.ExportReport
  alias TaskArchitecture.Repo
  alias TaskArchitecture.Services.Export.StorageClient.DevStorage
  alias TaskArchitecture.Services.ExportOrganizations

  @standard_await_time 300

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
      |> Repo.preload([:export_companies, :companies])

    {:ok, example_result} = File.read("#{File.cwd!()}/test/feed_files/apec_example.xml")

    file_folder = DevStorage.file_folder()

    on_exit(make_ref(), fn ->
      DevStorage.delete_from_storage(company.organization_reference, export)
      File.rmdir("#{File.cwd!()}/#{file_folder}/#{export.id}")
      File.rm("#{File.cwd!()}/#{file_folder}/apec.xml")
    end)

    {
      :ok,
      export: export,
      invalid_export: invalid_export,
      company: company,
      file_folder: file_folder,
      example_result: example_result
    }
  end

  describe "#report_export_finished" do
    test "Does not render anything if pid for export is absent in the state.", %{
      export: export,
      file_folder: file_folder
    } do
      refute file_present?(file_folder, "apec.xml")
      export = Repo.preload(export, [:export_companies, :companies])

      export_report = %ExportReport{export: export}

      refute ExportOrganizations.export_is_running?(export)

      log =
        capture_log(fn ->
          :ok = ExportOrganizations.report_export_finished(self(), {:ok, export_report})
          :timer.sleep(300)
        end)

      assert log =~
               "TaskArchitecture.Services.ExportOrganizations Export for given PID not found in state"
    end
  end

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

  describe "#render_export_result" do
    setup %{export: export, company: company1} do
      export_type = "apec"

      company2 =
        company_fixture(%{
          organization_reference: "reference222222222",
          access_token: "token",
          apec_manual_fields: @apec_limitation_rules_params
        })

      export_company_fixture(%{company_id: company2.id, export_id: export.id})

      {:ok, content_example_1} =
        File.read("#{File.cwd!()}/test/feed_files/render_result_contents/content_example_1.xml")

      {:ok, content_example_2} =
        File.read("#{File.cwd!()}/test/feed_files/render_result_contents/content_example_2.xml")

      DevStorage.write_to_storage(content_example_1, company1.organization_reference, export)
      DevStorage.write_to_storage(content_example_2, company2.organization_reference, export)

      on_exit(make_ref(), fn ->
        DevStorage.delete_from_storage(company1.organization_reference, export)
        DevStorage.delete_from_storage(company2.organization_reference, export)
      end)

      {:ok, export_type: export_type}
    end

    test "Render file of the given type if there are some active export of given type", %{
      file_folder: file_folder,
      example_result: example_result,
      export_type: export_type
    } do
      refute file_present?(file_folder, "#{export_type}.xml")

      log =
        capture_log(fn ->
          assert :ok = ExportOrganizations.render_export_result(export_type)
          # timeout added to perform fetching records and rendering xml
          :timer.sleep(300)
        end)

      assert log =~
               "TaskArchitecture.Services.ExportOrganizations Successfully updated XML feed file for #{
                 export_type
               } type"

      assert file_present?(file_folder, "#{export_type}.xml")

      {:ok, written_content} = File.read("#{File.cwd!()}/#{file_folder}/apec.xml")

      assert example_result == written_content
    end

    test "Does not render file if no active export of given type", %{
      invalid_export: invalid_export,
      export: export,
      file_folder: file_folder,
      export_type: export_type
    } do
      Exports.update_export(export, %{active: false})
      Exports.update_export(invalid_export, %{active: false})
      :timer.sleep(100)

      refute file_present?(file_folder, "#{export_type}.xml")

      assert {:error, "No active exports"} = ExportOrganizations.render_export_result(export_type)

      refute file_present?(file_folder, "#{export_type}.xml")
    end

    test "Does not render file if there are no exports of given type", %{file_folder: file_folder} do
      export_type = "mistic_type"
      refute file_present?(file_folder, "#{export_type}.xml")

      assert {:error, "Invalid export type #{export_type}"} ==
               ExportOrganizations.render_export_result(export_type)

      refute file_present?(file_folder, "#{export_type}.xml")
    end
  end

  describe "#run_exports" do
    test "Render content when export is valid. Store synchronization export id in state. Create report.",
         %{
           export: export,
           invalid_export: invalid_export,
           file_folder: file_folder
         } do
      refute file_present?(file_folder, "apec.xml")
      export_type = export.export_target_type
      export = Repo.preload(export, [:export_companies, companies: :export_companies])

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      log =
        capture_log(fn ->
          assert {:ok, 1} = ExportOrganizations.run_exports([export], start_type: "manual")
          assert ExportOrganizations.export_is_running?(export)
          refute ExportOrganizations.export_is_running?(invalid_export)
          # timeout added to perform fetching records and rendering xml
          :timer.sleep(300)
        end)

      assert log =~
               "CreateExportJob report for export: ID: #{export.id}, name: #{export.name}, has been successfully created"

      assert log =~
               "TaskArchitecture.Services.ExportOrganizations Successfully updated XML feed file after #{
                 export.name
               } Export of #{export_type} type"

      timeout_assert(fn ->
        assert file_present?(file_folder, "apec.xml")
        assert before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end

    test "Does not render content when export is invalid. Create report.",
         %{
           invalid_export: invalid_export,
           file_folder: file_folder
         } do
      refute file_present?(file_folder, "apec.xml")
      invalid_export = Repo.preload(invalid_export, [:export_companies, :companies])

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      log =
        capture_log(fn ->
          assert {:ok, 1} =
                   ExportOrganizations.run_exports([invalid_export], start_type: "manual")

          assert ExportOrganizations.export_is_running?(invalid_export)
          :timer.sleep(@standard_await_time)
        end)

      assert log =~
               "CreateExportJob report for export: ID: #{invalid_export.id}, name: #{
                 invalid_export.name
               }, has been successfully created"

      assert log =~
               "TaskArchitecture.Services.ExportOrganizations Failed to update XML file. Reason: Export process failed"

      timeout_assert(fn ->
        refute file_present?(file_folder, "apec.xml")
        assert before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end

    test "Does not render content when all export companies are invalid.",
         %{
           invalid_export: invalid_export,
           file_folder: file_folder
         } do
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

      refute file_present?(file_folder, "apec.xml")

      invalid_export =
        Repo.preload(invalid_export, [:export_companies, :companies])
        |> Map.put(:companies, [invalid_company])

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      log =
        capture_log(fn ->
          assert {:ok, 1} =
                   ExportOrganizations.run_exports([invalid_export], start_type: "manual")

          assert ExportOrganizations.export_is_running?(invalid_export)
          :timer.sleep(@standard_await_time)
        end)

      assert log =~
               "CreateExportJob report for export: ID: #{invalid_export.id}, name: #{
                 invalid_export.name
               }, has been successfully created"

      assert log =~
               "TaskArchitecture.Services.ExportOrganizations Failed to update XML file. Reason: Export process failed"

      timeout_assert(fn ->
        refute file_present?(file_folder, "apec.xml")
        assert before_export_report_count + 1 == Repo.aggregate(ExportJob, :count, :id)
      end)
    end
  end

  describe "#start_scheduled" do
    test "Start all active reports. Create reports.",
         %{
           export: export,
           invalid_export: invalid_export,
           file_folder: file_folder
         } do
      export_type = export.export_target_type
      refute file_present?(file_folder, "#{export_type}.xml")

      active_exports_count =
        Exports.list_active_exports(nil, [:export_companies, :companies])
        |> length()

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      log =
        capture_log(fn ->
          assert {:ok, 2} = ExportOrganizations.start_scheduled()
          assert ExportOrganizations.export_is_running?(export)
          assert ExportOrganizations.export_is_running?(invalid_export)
          # timeout added to perform fetching records and rendering xml
          :timer.sleep(@standard_await_time)
        end)

      assert log =~
               "CreateExportJob report for export: ID: #{export.id}, name: #{export.name}, has been successfully created"

      assert log =~
               "CreateExportJob report for export: ID: #{invalid_export.id}, name: #{
                 invalid_export.name
               }, has been successfully created"

      assert log =~
               "TaskArchitecture.Services.ExportOrganizations Successfully updated XML feed file after #{
                 export.name
               } Export of #{export_type} type"

      timeout_assert(fn ->
        assert file_present?(file_folder, "#{export_type}.xml")

        assert before_export_report_count + active_exports_count ==
                 Repo.aggregate(ExportJob, :count, :id)
      end)
    end

    test "Does not start anything if there is no active exports. Does not create export reports",
         %{
           export: export,
           invalid_export: invalid_export,
           file_folder: file_folder
         } do
      export_type = export.export_target_type
      Exports.update_export(export, %{active: false})
      Exports.update_export(invalid_export, %{active: false})
      :timer.sleep(100)

      refute file_present?(file_folder, "#{export_type}.xml")

      before_export_report_count = Repo.aggregate(ExportJob, :count, :id)

      log =
        capture_log(fn ->
          assert {:ok, 0} = ExportOrganizations.start_scheduled()
          refute ExportOrganizations.export_is_running?(export)
          refute ExportOrganizations.export_is_running?(invalid_export)
          # timeout added to perform fetching records and rendering xml
          :timer.sleep(@standard_await_time)
        end)

      refute log =~
               "CreateExportJob report for export: ID: #{export.id}, name: #{export.name}, has been successfully created"

      refute log =~
               "CreateExportJob report for export: ID: #{invalid_export.id}, name: #{
                 invalid_export.name
               }, has been successfully created"

      timeout_assert(fn ->
        refute file_present?(file_folder, "#{export_type}.xml")
        assert before_export_report_count == Repo.aggregate(ExportJob, :count, :id)
      end)
    end
  end

  describe "#export_is_running?" do
    test "return true if process has run and false when process has not run", %{
      export: export,
      invalid_export: invalid_export
    } do
      assert {:ok, 1} = ExportOrganizations.run_exports([export], start_type: "manual")
      assert ExportOrganizations.export_is_running?(export)
      refute ExportOrganizations.export_is_running?(invalid_export)
    end
  end

  defp file_present?(path, file_name) do
    case File.ls(path) do
      {:ok, files_list} ->
        Enum.any?(files_list, fn v ->
          v == file_name
        end)

      _ ->
        false
    end
  end
end
