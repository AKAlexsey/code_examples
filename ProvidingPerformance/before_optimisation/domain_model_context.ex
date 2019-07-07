# Context for requesting data from Mnesia. According to Phoenix best practices separate context from model itself.
# In real application there are a lot of functions but here I left only necessary for explaining the case.
defmodule ExampleApplicationServer.DomainModelContext do
  @moduledoc false

  require Amnesia
  require Amnesia.Helper

  # Documentation shows what's the problem "ITERATE THROUGH" that was the problem
  @doc """
  Iterate through all subnets and choose all those matches given IP address.
  """
  @spec get_subnets_for_ip(binary) :: map() | []
  def get_subnets_for_ip(ip_address) do
    Amnesia.transaction(fn ->
      # When function calls it run over EACH record sequentially and apply concat_subnet_if_it_matches
      # In 2019 it's fast but for 1000 records is not so fast. Approximately 5-10 ms.
      Amnesia.Table.foldl(DomainModel.Subnet, [], fn {_, _, _, _, parsed_cidr, _} = subnet, acc ->
        concat_subnet_if_it_matches(parsed_cidr, ip_address, acc, subnet)
      end)
    end)
    |> Enum.sort_by(fn {_, _, _, _, parsed_cidr, _} -> -1 * parsed_cidr.mask end)
    |> Enum.map(fn attrs -> DomainModel.make_table_record(attrs) end)
  end

  defp concat_subnet_if_it_matches(parsed_cidr, ip_address, acc, subnet) do
    if(CIDR.match!(parsed_cidr, ip_address), do: acc ++ [subnet], else: acc)
  end
end
