use Amnesia

# Implementing table inside Mnesia database using Amnesia hex package.
# Contains only necessary fields(We don't need :updated_at, :created_at fields for example)
# Also contains :server_group_ids and :program_record_ids to provide consistency of links between records.
defdatabase DomainModel do
  deftable Server,
           [
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
             :healthcheck_path,
             :server_group_ids,
             :program_record_ids
           ],
           type: :ordered_set,
           copying: [memory: NodesService.get_nodes()] do
    @type t :: %Server{
            id: integer,
            type: String.t(),
            domain_name: String.t(),
            ip: String.t(),
            port: integer,
            status: String.t(),
            availability: boolean,
            weight: integer,
            prefix: String.t(),
            healthcheck_enabled: true,
            healthcheck_path: String.t(),
            server_group_ids: list(integer),
            program_record_ids: list(integer)
          }
  end
end
