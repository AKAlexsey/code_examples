# Handler implementation for certain Mnesia table
defmodule ExampleProject.DomainModelHandlers.ServerHandler do
  @moduledoc false

  alias DomainModel.Server

  # Pass necessary data to configuration
  use ExampleProject.DomainModelHandlers.AbstractHandler,
    # Table name
    table: Server,
    # Joined models.
    joined_attributes_and_models: [
      # If server_group_ids value has been changed, Mnesia handler will request ServerGroup
      # models from database.
      server_group_ids: "ServerGroup",
      program_record_ids: "ProgramRecord"
    ],
    # Some of linked Mnesia tables depends from this record fields. Because it's using in complex search index.
    models_with_injected_attribute: [
      # If :prefix field has been changed, handler will request all lined ProgramRecord
      # with ids located inside :program_record_ids fields
      {:prefix, "ProgramRecord", :program_record_ids}
    ]
end
