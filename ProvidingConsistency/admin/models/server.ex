defmodule ExampleProject.Servers.Server do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias ExampleProject.Content.ProgramRecord
  alias ExampleProject.{Repo, Servers}
  alias ExampleProject.Observers.{CrudActionsLogger, DomainModelNotifier, DomainModelObserver}
  alias ExampleProject.Servers.{ServerGroup, ServerGroupServer}


  # This is using observer pattern in certain model.
  # It's implementation inside `/ProvidingConsistency/admin/observers/domain_model_notifier.ex`
  use DomainModelNotifier, observers: [CrudActionsLogger, DomainModelObserver]
  # The callback those run after any CRUD action is inside `/ProvidingConsistency/admin/observers/domain_model_observer.ex`
  # By the way except providing consistency I used this mechanism for logging database CRUD actions.
  # Logging module inside `/ProvidingConsistency/admin/observers/crud_actions_logger.ex`

  @cast_fields [
    :type,
    :domain_name,
    :ip,
    :port,
    :manage_ip,
    :manage_port,
    :status,
    :availability,
    :weight,
    :prefix,
    :healthcheck_enabled,
    :healthcheck_path
  ]
  @required_fields [:type, :domain_name, :ip, :port, :status, :weight]

  schema "servers" do
    field(:domain_name, :string)
    field(:healthcheck_enabled, :boolean, default: true)
    field(:healthcheck_path, :string)
    field(:ip, :string)
    field(:manage_ip, :string)
    field(:manage_port, :integer)
    field(:port, :integer)
    field(:prefix, :string)
    field(:status, :string)
    field(:availability, :boolean, default: true)
    field(:type, :string)
    field(:weight, :integer)

    # There are several linked records. To provide consistency inside cache we must send data for all linked records.
    # Besides that there is must be one common interface for all models. The solution is: Using protocols
    # Protocol example is inside `/ProvidingConsistency/admin/protocols/`
    has_many(
      :server_group_servers,
      ServerGroupServer,
      foreign_key: :server_id,
      on_replace: :delete,
      on_delete: :delete_all
    )

    many_to_many(:server_groups, ServerGroup, join_through: ServerGroupServer)

    has_many(:program_records, ProgramRecord, foreign_key: :server_id)

    timestamps()
  end

  @doc false
  def changeset(%{id: id} = server, attrs) do
    # ....
  end
end
