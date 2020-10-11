defmodule TaskArchitecture.Exports.FiltrationRulesFormObjectTest do
  use TaskArchitecture.DataCase, async: false

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.ExportCompanyEmbedded.Rule
  alias TaskArchitecture.Exports.FiltrationRulesFormObject

  setup do
    company = company_fixture(%{organization_reference: "reference", access_token: "token"})

    export =
      export_fixture(%{name: "First export", limitation_rules: "", export_target_type: "apec"})

    export_company = export_company_fixture(%{export_id: export.id, company_id: company.id})

    {:ok, export: export, company: company, export_company: export_company}
  end

  describe "#new" do
    test "Set rules to default list if no :filtration_rule_id given", %{
      export_company: export_company
    } do
      assert %FiltrationRulesFormObject{
               export_company: ^export_company,
               rules: [%Rule{}],
               filtration_rule_id: nil
             } = FiltrationRulesFormObject.new(export_company)
    end

    test "Set rules to rules from given as :filtration_rule_id filtration_rules", %{
      export_company: export_company
    } do
      %{
        export_company: export_company,
        filtration_rule_id: filtration_rule_id,
        rule1_field: rule1_field,
        rule2_field: rule2_field
      } = add_rules_to_company(export_company)

      assert %FiltrationRulesFormObject{
               export_company: ^export_company,
               rules: [%Rule{field: ^rule1_field}, %Rule{field: ^rule2_field}],
               filtration_rule_id: ^filtration_rule_id
             } = FiltrationRulesFormObject.new(export_company, filtration_rule_id)
    end
  end

  describe "#create_filtration_rule" do
    setup %{export_company: export_company} do
      form_object = FiltrationRulesFormObject.new(export_company)

      new_rules_params = [
        %{"field" => "profile", "value" => "second", "operation" => "contains"},
        %{"field" => "language", "value" => "fifth", "operation" => "equal"}
      ]

      {:ok, form_object: form_object, new_rules_params: new_rules_params}
    end

    test "Add new FiltrationRule to export company if there are no rules for a while", %{
      form_object: form_object,
      export_company: export_company,
      new_rules_params: new_rules_params
    } do
      assert count_filtration_rules(export_company) == 0

      assert {:ok, valid_form_object} =
               FiltrationRulesFormObject.create_filtration_rule(
                 form_object,
                 %{"rules" => new_rules_params}
               )

      assert count_filtration_rules(export_company) == 1
    end

    test "Add new FiltrationRule to export company if rules already exists", %{
      export_company: export_company,
      new_rules_params: new_rules_params
    } do
      %{export_company: export_company} = add_rules_to_company(export_company)

      assert count_filtration_rules(export_company) == 2

      form_object = FiltrationRulesFormObject.new(export_company)

      assert {:ok, valid_form_object} =
               FiltrationRulesFormObject.create_filtration_rule(
                 form_object,
                 %{"rules" => new_rules_params}
               )

      assert count_filtration_rules(export_company) == 3
    end

    test "Return error changeset if given filtering rules are invalid", %{
      form_object: form_object,
      export_company: export_company
    } do
      assert count_filtration_rules(export_company) == 0

      new_rules_params = [
        %{"field" => nil, "value" => "second", "operation" => "contains"},
        %{"field" => "description", "value" => "fifth", "operation" => nil},
        %{"field" => "profile", "value" => "eighth", "operation" => "equal"}
      ]

      assert {:error, error_changeset} =
               FiltrationRulesFormObject.create_filtration_rule(
                 form_object,
                 %{"rules" => new_rules_params}
               )

      assert count_filtration_rules(export_company) == 0

      assert has_error?(error_changeset, :rules, "Some rules invalid")
      %{changes: %{rules: [first_rule, second_rule, third_rule]}} = error_changeset

      assert has_error?(first_rule, :field, "can't be blank")
      assert has_error?(second_rule, :operation, "can't be blank")
      assert third_rule.valid?
    end
  end

  describe "#update_filtration_rule" do
    setup %{export_company: export_company} do
      %{
        export_company: export_company,
        filtration_rule_id: filtration_rule_id,
        rule1_field: rule1_field,
        rule2_field: rule2_field,
        rule3_field: rule3_field,
        rule1_value: rule1_value,
        rule2_value: rule2_value,
        rule3_value: rule3_value,
        rule1_operation: rule1_operation,
        rule2_operation: rule2_operation,
        rule3_operation: rule3_operation
      } = add_rules_to_company(export_company)

      form_object = FiltrationRulesFormObject.new(export_company, filtration_rule_id)

      {
        :ok,
        form_object: form_object,
        export_company: export_company,
        filtration_rule_id: filtration_rule_id,
        rule1_field: rule1_field,
        rule2_field: rule2_field,
        rule3_field: rule3_field,
        rule1_value: rule1_value,
        rule2_value: rule2_value,
        rule3_value: rule3_value,
        rule1_operation: rule1_operation,
        rule2_operation: rule2_operation,
        rule3_operation: rule3_operation
      }
    end

    test "Update fields if params are valid", %{
      form_object: form_object,
      rule1_field: rule1_field,
      rule1_operation: rule1_operation,
      filtration_rule_id: filtration_rule_id,
      export_company: export_company
    } do
      update_rules_params = [
        %{"field" => rule1_field, "value" => "second", "operation" => rule1_operation},
        %{"field" => "description", "value" => "fifth", "operation" => "contains"}
      ]

      assert count_filtration_rules(export_company) == 2

      assert {:ok, valid_form_object} =
               FiltrationRulesFormObject.update_filtration_rule(
                 form_object,
                 %{"rules" => update_rules_params}
               )

      assert count_filtration_rules(export_company) == 2

      updated_export_company = Exports.get_export_company!(export_company.id)

      updated_rule_group =
        updated_export_company.filtration_rules
        |> Enum.find(fn %{id: id} -> id == filtration_rule_id end)

      assert %{
               rules: [
                 %Rule{field: rule1_field, value: "second", operation: rule1_operation},
                 %Rule{field: "description", value: "fifth", operation: "contains"}
               ]
             } = updated_rule_group
    end

    test "Reduce amount of rules if less amounts of params are given", %{
      form_object: form_object,
      filtration_rule_id: filtration_rule_id,
      export_company: export_company
    } do
      update_rules_params = [
        %{"field" => "remote", "value" => "fifth", "operation" => "contains"}
      ]

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3

      assert {:ok, valid_form_object} =
               FiltrationRulesFormObject.update_filtration_rule(
                 form_object,
                 %{"rules" => update_rules_params}
               )

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 2

      updated_export_company = Exports.get_export_company!(export_company.id)

      updated_rule_group =
        updated_export_company.filtration_rules
        |> Enum.find(fn %{id: id} -> id == filtration_rule_id end)

      assert %{
               rules: [
                 %Rule{field: "remote", value: "fifth", operation: "contains"}
               ]
             } = updated_rule_group
    end

    test "Increase amount of rules if less amounts of params are given", %{
      form_object: form_object,
      rule1_field: rule1_field,
      rule1_operation: rule1_operation,
      filtration_rule_id: filtration_rule_id,
      export_company: export_company
    } do
      update_rules_params = [
        %{"field" => rule1_field, "value" => "second", "operation" => rule1_operation},
        %{"field" => "profile", "value" => "fifth", "operation" => "contains"},
        %{"field" => "office_id", "value" => "eights", "operation" => "contains"}
      ]

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3

      assert {:ok, valid_form_object} =
               FiltrationRulesFormObject.update_filtration_rule(
                 form_object,
                 %{"rules" => update_rules_params}
               )

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 4

      updated_export_company = Exports.get_export_company!(export_company.id)

      updated_rule_group =
        updated_export_company.filtration_rules
        |> Enum.find(fn %{id: id} -> id == filtration_rule_id end)

      assert %{
               rules: [
                 %Rule{field: rule1_field, value: "second", operation: rule1_operation},
                 %Rule{field: "profile", value: "fifth", operation: "contains"},
                 %Rule{field: "office_id", value: "eights", operation: "contains"}
               ]
             } = updated_rule_group
    end

    test "Return error changeset if given params invalid", %{
      form_object: form_object,
      rule1_operation: rule1_operation,
      export_company: export_company
    } do
      update_rules_params = [
        %{"field" => nil, "value" => "second", "operation" => rule1_operation},
        %{"field" => "language", "value" => "fifth", "operation" => "contains"}
      ]

      assert count_filtration_rules(export_company) == 2

      assert {:error, error_changeset} =
               FiltrationRulesFormObject.update_filtration_rule(
                 form_object,
                 %{"rules" => update_rules_params}
               )

      assert has_error?(error_changeset, :rules, "Some rules invalid")
      %{changes: %{rules: [_, _, first_rule, second_rule]}} = error_changeset

      assert has_error?(first_rule, :field, "can't be blank")
      assert second_rule.valid?
    end

    test "Return error if form object does not have :filtration_rule_id", %{
      rule1_field: rule1_field,
      rule1_operation: rule1_operation,
      export_company: export_company
    } do
      form_object = FiltrationRulesFormObject.new(export_company)

      assert {:error, error_changeset} =
               FiltrationRulesFormObject.update_filtration_rule(
                 form_object,
                 %{
                   "rules" => [
                     %{
                       "field" => rule1_field,
                       "value" => "second",
                       "operation" => rule1_operation
                     },
                     %{"field" => "fourth", "value" => "fifth", "operation" => "contains"}
                   ]
                 }
               )

      assert has_error?(error_changeset, :filtration_rule_id, "can't be blank")
      refute has_error?(error_changeset, :rules, "Some rules invalid")
    end
  end

  describe "#delete_filtration_rule" do
    setup %{export_company: export_company} do
      %{
        export_company: export_company,
        filtration_rule_id: filtration_rule_id,
        rule1_field: rule1_field,
        rule2_field: rule2_field,
        rule3_field: rule3_field,
        rule1_value: rule1_value,
        rule2_value: rule2_value,
        rule3_value: rule3_value,
        rule1_operation: rule1_operation,
        rule2_operation: rule2_operation,
        rule3_operation: rule3_operation
      } = add_rules_to_company(export_company)

      form_object = FiltrationRulesFormObject.new(export_company, filtration_rule_id)

      {
        :ok,
        form_object: form_object,
        export_company: export_company,
        filtration_rule_id: filtration_rule_id,
        rule1_field: rule1_field,
        rule2_field: rule2_field,
        rule3_field: rule3_field,
        rule1_value: rule1_value,
        rule2_value: rule2_value,
        rule3_value: rule3_value,
        rule1_operation: rule1_operation,
        rule2_operation: rule2_operation,
        rule3_operation: rule3_operation
      }
    end

    test "Delete rule if rule exists", %{
      form_object: form_object,
      export_company: export_company
    } do
      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3

      assert :ok = FiltrationRulesFormObject.delete_filtration_rule(form_object)

      assert count_filtration_rules(export_company) == 1
      assert count_total_rules(export_company) == 1
    end

    test "Return error if rule with necessary id does not exist", %{
      export_company: export_company
    } do
      form_object = FiltrationRulesFormObject.new(export_company, "invalid-id")

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3

      assert {:error, "Rule with given id does not exist"} =
               FiltrationRulesFormObject.delete_filtration_rule(form_object)

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3
    end

    test "Return error if form object does not have :filtration_rule_id", %{
      export_company: export_company
    } do
      form_object = FiltrationRulesFormObject.new(export_company)

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3

      assert {:error, "Form object does not have :filtration_rule_id"} =
               FiltrationRulesFormObject.delete_filtration_rule(form_object)

      assert count_filtration_rules(export_company) == 2
      assert count_total_rules(export_company) == 3
    end
  end

  def add_rules_to_company(export_company) do
    rule1_field = "description"
    rule2_field = "profile"
    rule3_field = "remote"
    rule1_value = "value1"
    rule2_value = "value2"
    rule3_value = "value3"
    rule1_operation = "equal"
    rule2_operation = "contains"
    rule3_operation = "equal"

    {:ok, updated_export_company} =
      Exports.update_export_company(export_company, %{
        filtration_rules: [
          %{
            rules: [
              %{
                field: rule1_field,
                value: rule1_value,
                operation: rule1_operation
              },
              %{
                field: rule2_field,
                value: rule2_value,
                operation: rule2_operation
              }
            ]
          },
          %{
            rules: [
              %{
                field: rule3_field,
                value: rule3_value,
                operation: rule3_operation
              }
            ]
          }
        ]
      })

    filtration_rule_id =
      updated_export_company.filtration_rules
      |> Enum.find(fn %{rules: rules} -> length(rules) == 2 end)
      |> (fn %{id: id} -> id end).()

    %{
      export_company: updated_export_company,
      filtration_rule_id: filtration_rule_id,
      rule1_field: rule1_field,
      rule2_field: rule2_field,
      rule3_field: rule3_field,
      rule1_value: rule1_value,
      rule2_value: rule2_value,
      rule3_value: rule3_value,
      rule1_operation: rule1_operation,
      rule2_operation: rule2_operation,
      rule3_operation: rule3_operation
    }
  end

  def has_error?(changeset, field, value) do
    changeset
    |> Map.get(:errors)
    |> Keyword.get(field)
    |> (fn
          {message, _} ->
            message == value

          _ ->
            false
        end).()
  end

  def count_filtration_rules(%{id: id}) do
    id
    |> Exports.get_export_company!()
    |> (fn %{filtration_rules: filtration_rules} -> length(filtration_rules) end).()
  end

  def count_total_rules(%{id: id}) do
    id
    |> Exports.get_export_company!()
    |> (fn %{filtration_rules: filtration_rules} ->
          Enum.map(filtration_rules, &Map.get(&1, :rules))
        end).()
    |> List.flatten()
    |> length()
  end
end
