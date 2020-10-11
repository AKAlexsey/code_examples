defmodule TaskArchitecture.Exports.ExportCompanyFormObjectTest do
  use TaskArchitecture.DataCase, async: false

  alias TaskArchitecture.Exports.{Company, ExportCompany, ExportCompanyFormObject}
  alias TaskArchitecture.Repo

  setup do
    company = company_fixture(%{organization_reference: "reference", access_token: "token"})

    export =
      export_fixture(%{name: "First export", limitation_rules: "", export_target_type: "apec"})

    blank = ExportCompanyFormObject.new()

    {:ok, export: export, company: company, blank: blank}
  end

  describe "#from if only export_id and company_id given" do
    test "create ExportCompany if params is valid", %{
      export: export,
      company: company,
      blank: blank
    } do
      before_company_count = count_records(Company)
      before_export_company = count_records(ExportCompany)

      assert {:ok, result} =
               ExportCompanyFormObject.create(blank, %{
                 export_id: export.id,
                 company_id: company.id
               })

      timeout_assert(fn ->
        assert before_company_count == count_records(Company)
        assert before_export_company + 1 == count_records(ExportCompany)
      end)
    end

    test "return error if export_company with such references already exists", %{
      export: export,
      company: company,
      blank: blank
    } do
      export_company_fixture(%{export_id: export.id, company_id: company.id})
      before_company_count = count_records(Company)
      before_export_company = count_records(ExportCompany)

      assert {:error, changeset} =
               ExportCompanyFormObject.create(blank, %{
                 export_id: export.id,
                 company_id: company.id
               })

      assert has_error?(changeset, :company_id, "This relation already exists.")

      timeout_assert(fn ->
        assert before_company_count == count_records(Company)
        assert before_export_company == count_records(ExportCompany)
      end)
    end

    test "return error if export_id or company_id is empty", %{
      blank: blank
    } do
      before_company_count = count_records(Company)
      before_export_company = count_records(ExportCompany)

      assert {:error, changeset} =
               ExportCompanyFormObject.create(blank, %{export_id: nil, company_id: nil})

      assert has_error?(changeset, :company_id, "can't be blank")
      assert has_error?(changeset, :export_id, "can't be blank")

      timeout_assert(fn ->
        assert before_company_count == count_records(Company)
        assert before_export_company == count_records(ExportCompany)
      end)
    end
  end

  describe "#from if company organization_reference given" do
    test "create ExportCompany and Company if params is valid", %{
      export: export,
      blank: blank
    } do
      before_company_count = count_records(Company)
      before_export_company = count_records(ExportCompany)

      assert {:ok, result} =
               ExportCompanyFormObject.create(blank, %{
                 export_id: export.id,
                 organization_reference: "new_reference",
                 access_token: "token"
               })

      timeout_assert(fn ->
        assert before_company_count + 1 == count_records(Company)
        assert before_export_company + 1 == count_records(ExportCompany)
      end)
    end

    test "return error if Company params invalid", %{
      export: export,
      blank: blank
    } do
      before_company_count = count_records(Company)
      before_export_company = count_records(ExportCompany)

      assert {:error, changeset} =
               ExportCompanyFormObject.create(blank, %{
                 export_id: export.id,
                 organization_reference: "new_reference"
               })

      assert has_error?(changeset, :access_token, "can't be blank")

      timeout_assert(fn ->
        assert before_company_count == count_records(Company)
        assert before_export_company == count_records(ExportCompany)
      end)
    end

    test "return error if company with such organization_reference already exists", %{
      export: export,
      company: company,
      blank: blank
    } do
      before_company_count = count_records(Company)
      before_export_company = count_records(ExportCompany)

      assert {:error, changeset} =
               ExportCompanyFormObject.create(blank, %{
                 export_id: export.id,
                 organization_reference: company.organization_reference,
                 access_token: "token"
               })

      assert has_error?(changeset, :organization_reference, "has already been taken")

      timeout_assert(fn ->
        assert before_company_count == count_records(Company)
        assert before_export_company == count_records(ExportCompany)
      end)
    end
  end

  def has_error?(changeset, field, value) do
    changeset
    |> Map.get(:errors)
    |> Keyword.get(field)
    |> (fn {message, _} -> message == value end).()
  end

  def count_records(type) do
    Repo.aggregate(type, :count, :id)
  end
end
