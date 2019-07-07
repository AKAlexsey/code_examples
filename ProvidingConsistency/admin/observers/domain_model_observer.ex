# Observer runs on each CRUD action and send to mnesia handler:
# 1. Action(:insert, :update, :delete);
# 2. model_name for recognising in which table we must write data;
# 3. attrs - Pass model to NotifyServerAttrs protocol those return map with allowed and necessary fields.
defmodule ExampleProject.Observers.DomainModelObserver do
  @moduledoc false
  use Observable, :observer

  alias ExampleProject.Protocols.NotifyServerAttrs

  # Common interface fo all tables those send data to appropriate Mnesia handler
  # Must implement ExampleProject.Handlers.AbstractHandler behaviour
  @handler Application.get_env(:example_project, :domain_model_handler)

  defp handler, do: @handler

  def handle_notify({:insert, record}) do
    handler().handle(:insert, %{
      model_name: model_name(record),
      attrs: NotifyServerAttrs.get(record)
    })

    :ok
  end

  def handle_notify({:update, [_old_record, new_record]}) do
    handler().handle(:update, %{
      model_name: model_name(new_record),
      attrs: NotifyServerAttrs.get(new_record)
    })

    :ok
  end

  def handle_notify({:delete, record}) do
    handler().handle(:delete, %{
      model_name: model_name(record),
      attrs: NotifyServerAttrs.get(record)
    })

    :ok
  end

  defp model_name(record) do
    record.__struct__
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
end
