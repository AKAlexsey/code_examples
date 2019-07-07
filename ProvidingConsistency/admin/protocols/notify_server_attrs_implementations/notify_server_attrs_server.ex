alias ExampleProject.Servers.Server
alias ExampleProject.Protocols.NotifyServerAttrs
alias ExampleProject.Servers.ServerGroupServer
alias ExampleProject.Content.ProgramRecord
alias ExampleProject.Repo

import Ecto.Query

defimpl NotifyServerAttrs, for: Server do
  # First of all protocol must contain write list of permitted attributes
  @permitted_attrs [
    :id,
    :type,
    :domain_name,
    :ip,
    :port,
    :status,
    :availability,
    :weight,
    :prefix,
    :healthcheck_enabled,
    :healthcheck_path
  ]

  # API implementation
  def get(%Server{} = record) do
    # First we must take only permitted attributes
    record
    |> Map.from_struct()
    |> Map.split(@permitted_attrs)
    |> (fn {permitted, _filtered} -> permitted end).()
    # Observable mechanism runs when you run Repo methods create_and_notify, update_and_notify and delete_and_notify
    # And only for the model record itself. If association changes linked records will not be refreshed in Mnesia table.
    # For example: you have Server belongs_to ServerGroup link.
    # When you update Server server_group_id observable send data to Mnesia Server table but not Mnesia ServerGroup table.
    # For providing consistency we must store links somewhere.
    # I decided to store it in field in Mnesia table record.
    # So if links gonna change Mnesia handlers compare data with previous and refresh necessary tables.
    # For clarity see `/ProvidingConsistency/server/handlers/domain_model_handlers/abstract_handler.ex`
    |> preload_server_group_ids(record)
    |> preload_program_record_ids(record)
  end

  defp preload_server_group_ids(attrs, %{server_groups: server_groups})
       when is_list(server_groups) do
    put_server_group_ids(attrs, get_ids(server_groups))
  end

  defp preload_server_group_ids(attrs, %{id: server_id}) do
    server_group_ids =
      from(
        sgs in ServerGroupServer,
        select: sgs.server_group_id,
        where: sgs.server_id == ^server_id
      )
      |> Repo.all()

    put_server_group_ids(attrs, server_group_ids)
  end

  defp put_server_group_ids(attrs, server_group_ids) do
    attrs
    |> Map.put(:server_group_ids, server_group_ids)
  end

  defp preload_program_record_ids(attrs, %{program_records: program_records})
       when is_list(program_records) do
    put_program_record_ids(attrs, get_ids(program_records))
  end

  defp preload_program_record_ids(attrs, %{id: server_id}) do
    program_record_ids =
      from(
        pr in ProgramRecord,
        select: pr.id,
        where: pr.server_id == ^server_id
      )
      |> Repo.all()

    put_program_record_ids(attrs, program_record_ids)
  end

  defp put_program_record_ids(attrs, program_record_ids) do
    Map.put(attrs, :program_record_ids, program_record_ids)
  end

  defp get_ids(collection) do
    Enum.map(collection, & &1.id)
  end
end
