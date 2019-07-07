defmodule ExampleApplication.DomainModelHandlers.SubnetHandler do
  @moduledoc false

  alias DomainModel.Subnet
  import DomainModel, only: [cidr_fields_for_search: 1]

  use ExampleApplication.DomainModelHandlers.AbstractHandler,
    table: Subnet,
    joined_attributes_and_models: [
      region_id: "Region"
    ]

  def before_write(%{cidr: cidr} = struct, _raw_attrs) do
    # Write :first_number_ip and :last_number_ip before writing
    Map.merge(struct, cidr_fields_for_search(cidr))
  end
end
