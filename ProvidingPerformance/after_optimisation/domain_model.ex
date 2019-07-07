use Amnesia

# Better solution
defdatabase DomainModel do
  deftable Subnet,
           [
             :id,
             :region_id,
             :cidr,
             :parsed_cidr,
             :first_number_ip,
             :last_number_ip,
             :name
           ],
           type: :ordered_set do
    @type t :: %Subnet{
            id: integer,
            region_id: integer,
            cidr: String.t(),
            parsed_cidr: any,
            # Next two records has been added for storing ip addresses range
            first_number_ip: integer,
            last_number_ip: integer,
            name: String.t()
          }
  end

  def cidr_fields_for_search(cidr) do
    parsed_cidr = CIDR.parse(cidr)

    %{
      parsed_cidr: parsed_cidr,
      # Solution was to store CIDR IP ranges in two numbers and use
      # :mnesia.select instead of Amnesia.Table.foldl
      first_number_ip: CIDR.tuple2number(parsed_cidr.first, 0),
      last_number_ip: CIDR.tuple2number(parsed_cidr.last, 0)
    }
  end
end
