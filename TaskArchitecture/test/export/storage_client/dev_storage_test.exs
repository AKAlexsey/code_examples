defmodule TaskArchitecture.Services.Export.StorageClient.DevStorageTest do
  use TaskArchitecture.DataCase, async: false

  alias TaskArchitecture.Services.Export.StorageClient.DevStorage

  setup do
    {:ok, example_content} =
      File.read("#{File.cwd!()}/#{DevStorage.file_folder()}/feed_files_example.xml")

    export =
      export_fixture(%{
        name: "Export",
        export_target_type: "apec",
        limitation_rules: "limitation_rules"
      })

    organization_reference = "reference_1234"

    file_folder = DevStorage.file_folder()

    on_exit(make_ref(), fn ->
      DevStorage.delete_from_storage(organization_reference, export)
      File.rmdir("#{File.cwd!()}/#{file_folder}/#{export.id}")
    end)

    {:ok,
     organization_reference: organization_reference,
     example_content: example_content,
     export: export,
     file_folder: file_folder}
  end

  describe "#file_folder" do
    test "Return right filed folder" do
      assert "test/feed_files" == DevStorage.file_folder()
    end
  end

  describe "#write_to_storage" do
    test "Create file into necessary file",
         %{
           example_content: example_content,
           organization_reference: organization_reference,
           export: export,
           file_folder: file_folder
         } do
      refute file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")

      assert {:ok, ""} =
               DevStorage.write_to_storage(example_content, organization_reference, export)

      assert file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")
    end

    test "Return error is there is some error",
         %{
           example_content: example_content,
           organization_reference: organization_reference,
           export: export,
           file_folder: file_folder
         } do
      refute file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")

      assert {:error, :eisdir} = DevStorage.write_to_storage(example_content, "", export)

      refute file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")
    end
  end

  describe "#read_from_storage" do
    setup %{
      organization_reference: organization_reference,
      export: export,
      example_content: example_content
    } do
      DevStorage.write_to_storage(example_content, organization_reference, export)

      :ok
    end

    test "Read file if it exists", %{
      example_content: content_standard,
      organization_reference: organization_reference,
      export: export
    } do
      assert {:ok, ^content_standard} =
               DevStorage.read_from_storage(organization_reference, export)
    end

    test "Return error if file is absent", %{export: export} do
      assert {:error, :enoent} = DevStorage.read_from_storage("reference_2", export)
    end
  end

  describe "#delete_from_storage" do
    test "Remove file from storage", %{
      example_content: content_standard,
      organization_reference: organization_reference,
      export: export,
      file_folder: file_folder
    } do
      refute file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")

      assert {:ok, ""} =
               DevStorage.write_to_storage(content_standard, organization_reference, export)

      assert {:ok, ^content_standard} =
               DevStorage.read_from_storage(organization_reference, export)

      assert file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")

      assert {:ok, ""} = DevStorage.delete_from_storage(organization_reference, export)

      assert {:error, :enoent} = DevStorage.read_from_storage(organization_reference, export)

      refute file_present?("#{file_folder}/#{export.id}", "#{organization_reference}.xml")
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
