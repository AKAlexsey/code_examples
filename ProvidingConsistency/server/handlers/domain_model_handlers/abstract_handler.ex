# Common handler logic
# Allow to:
# 1. Write data to table
# 2. Track changes in lined fields and request if it changes
# 3. Perform manipulations between writing(for example create complex indexes for searching)
defmodule ExampleProject.DomainModelHandlers.AbstractHandler do
  @moduledoc false

  defmacro __using__(opts) do
    table = Keyword.get(opts, :table)
    joined_attributes_and_models = Keyword.get(opts, :joined_attributes_and_models, [])
    models_with_injected_attribute = Keyword.get(opts, :models_with_injected_attribute, [])

    quote do
      require Amnesia
      require Amnesia.Helper
      use ExampleProject.ExampleProjectLogger, metadata: [domain: :caching_system]

      @table unquote(table)
      @joined_attributes_and_models unquote(joined_attributes_and_models)
      @models_with_injected_attribute unquote(models_with_injected_attribute)
      @example_project_public_api Application.get_env(:example_project, :public_api)[:module]

      # Callbacks for different CRUD actions :insert, :update, :delete
      # :refresh_associated_records_if_necessary - provide linked records consistency
      # :refresh_models_with_injected_attribute - provide consistency for tables those contains different
      # records fields.
      # :write_to_table - write to appropriate table
      # :delete_from_table - deletes from table
      def handle(:insert, attrs) do
        log_info("Insert #{inspect(attrs)}")

        Amnesia.transaction do
          refresh_associated_records_if_necessary(attrs)
          write_to_table(attrs)
        end

        :ok
      end

      def handle(:update, attrs) do
        log_info("Update #{inspect(attrs)}")

        Amnesia.transaction do
          refresh_associated_records_if_necessary(attrs)
          refresh_models_with_injected_attribute(attrs)
          write_to_table(attrs)
        end

        :ok
      end

      def handle(:refresh_by_request, attrs) do
        log_info("Refresh by request #{inspect(attrs)}")

        Amnesia.transaction do
          write_to_table(attrs)
        end

        :ok
      end

      def handle(:delete, %{id: id} = attrs) do
        log_info("Delete #{inspect(attrs)}")

        Amnesia.transaction do
          delete_from_table(id)
          refresh_associated_records_if_necessary(attrs)
        end

        :ok
      end

      defp write_to_table(attrs) do
        @table.__struct__
        |> struct(attrs)
        |> before_write(attrs)
        |> @table.write()
      end

      # Can be used for manipulations with data before writing. For example adding complex index
      # You can see example in ProvidingConsistency/ProvidingConsistency/server/handlers/domain_model_handlers/tv_stream_handler.ex
      @doc """
      This functions calls right before writing to the mnesia table.
      Argument is table structure based on passed attributes.

      Could be used for preprocessing data before writing. For example:
      * Adding calculated attributes;
      * Preprocessing the attributes before writing;
      * Some other manipulations with attributes.
      """
      @spec before_write(map(), map()) :: map()
      def before_write(struct, _raw_attrs) do
        struct
      end

      defp delete_from_table(id) do
        @table.delete(id)
      end

      defp refresh_associated_records_if_necessary(%{id: id} = attrs) do
        id
        |> @table.read()
        |> check_associated_records_attributes(attrs)
      end

      defp check_associated_records_attributes(nil, attrs) do
        iterate_through_record_attributes(fn {joined_records_attribute, model_name} ->
          update_all_joined_records(attrs, joined_records_attribute, model_name)
        end)
      end

      defp check_associated_records_attributes(record, attrs) do
        iterate_through_record_attributes(fn {joined_records_attribute, model_name} ->
          current_value = Map.get(record, joined_records_attribute)
          new_value = Map.get(attrs, joined_records_attribute)

          compare_values_and_refresh(current_value, new_value, model_name)
        end)
      end

      defp iterate_through_record_attributes(callback) do
        @joined_attributes_and_models
        |> Enum.each(&callback.(&1))
      end

      defp refresh_models_with_injected_attribute(%{id: id} = attrs) do
        id
        |> @table.read()
        |> check_injected_attribute_joined_records(attrs)
      end

      defp check_injected_attribute_joined_records(record, attrs) do
        @models_with_injected_attribute
        |> Enum.each(fn {injected_attribute, model_name, joined_records_attribute} ->
          if Map.get(record, injected_attribute) != Map.get(attrs, injected_attribute) do
            update_all_joined_records(attrs, joined_records_attribute, model_name)
          else
            :ok
          end
        end)
      end

      defp update_all_joined_records(attrs, joined_records_attribute, model_name) do
        case Map.get(attrs, joined_records_attribute) do
          array_ids when is_list(array_ids) ->
            Enum.each(array_ids, &notify(model_name, &1))

          id ->
            notify(model_name, id)
        end
      end

      defp compare_values_and_refresh(current_value, new_value, model_name)
           when is_list(current_value) and is_list(new_value) do
        set1 = MapSet.new(current_value)
        set2 = MapSet.new(new_value)
        refresh_joined_models(set1, set2, model_name)
        refresh_joined_models(set2, set1, model_name)
      end

      defp compare_values_and_refresh(current_value, new_value, model_name) do
        if current_value != new_value do
          notify(model_name, current_value)
          notify(model_name, new_value)
        end
      end

      defp refresh_joined_models(set1, set2, model_name) do
        set1
        |> Enum.each(fn id ->
          if !MapSet.member?(set2, id) do
            notify(model_name, id)
          end
        end)
      end

      defp notify(_model_name, nil), do: :ok

      defp notify(model_name, id), do: @example_project_public_api.cache_model_record(model_name, id)

      defoverridable before_write: 2
    end
  end
end
