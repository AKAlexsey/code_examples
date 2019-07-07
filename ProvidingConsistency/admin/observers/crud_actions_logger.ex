# It's side effect of solution.
# First I added caching using observer pattern.
# Later when we needed to implement CRUD logging i realised that we can implement it just by adding
# new module to list into `use DomainModelNotifier` observers list.
# I like this example because it demonstrate host agile the system.
defmodule ExampleProject.Observers.CrudActionsLogger do
  @moduledoc false

  # Specific project logging module
  # We needed to separate logs from different domains
  use ExampleProject.ExampleProjectLogger, metadata: [domain: :database]
  use Observable, :observer

  alias ExampleProject.User

  @filter_string "[FILTERED]"

  def handle_notify({:insert, record}) do
    log_database_crud_operation(record, "Create")

    :ok
  end

  def handle_notify({:update, [_old_record, new_record]}) do
    log_database_crud_operation(new_record, "Update")

    :ok
  end

  def handle_notify({:delete, record}) do
    log_database_crud_operation(record, "Delete")

    :ok
  end

  defp log_database_crud_operation(record, operation) do
    log_info("#{operation} #{model_name(record)} #{inspect_record(record)}")
  end

  defp inspect_record(%User{} = user) do
    user
    |> Map.update!(:password, fn _val -> @filter_string end)
    |> Map.update!(:password_hash, fn _val -> @filter_string end)
    |> inspect()
  end

  defp inspect_record(record), do: inspect(record)

  defp model_name(record) do
    record.__struct__
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
end
