# This module invokes before writing necessary data to Mnesia
# For details you can see inside ProvidingConsistency folder
defmodule ExampleApplicationServer.DomainModelHandlers.SubnetHandler do
  @moduledoc false

  alias DomainModel.Subnet

  use ExampleApplicationServer.DomainModelHandlers.AbstractHandler,
    table: Subnet,
    joined_attributes_and_models: [
      region_id: "Region"
    ]

  def before_write(%{cidr: cidr} = struct) do
    # Here we write special data structure for not doing that every time we search.
    # But it's does not help us with good performance :)
    Map.put(struct, :parsed_cidr, CIDR.parse(cidr))
  end
end
