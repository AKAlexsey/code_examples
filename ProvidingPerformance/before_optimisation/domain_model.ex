use Amnesia

# First solution is rather straight forward. When you get Subnet data just write its CIDR inside appropriate field.
# Cidr is like 12.16.23.23/30 it's string.
# And I say again. Subnets count is approximately 1000.
defdatabase DomainModel do
  deftable Subnet, [:id, :region_id, :cidr, :parsed_cidr, :name], type: :ordered_set do
    @type t :: %Subnet{
            id: integer,
            region_id: integer,
            cidr: String.t(),
            parsed_cidr: any,
            name: String.t()
          }
  end

  def make_table_record(attrs) do
    list_attrs = Tuple.to_list(attrs)
    table = hd(list_attrs)
    values = Enum.slice(list_attrs, 1..-1)

    table.attributes()
    |> Keyword.keys()
    |> Enum.zip(values)
    |> Enum.into(%{})
    |> table.__struct__()
  end
end
