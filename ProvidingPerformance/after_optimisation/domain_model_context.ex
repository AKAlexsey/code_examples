# Same module but with fixed search function
defmodule ExampleApplication.DomainModelContext do
  @moduledoc false

  require Amnesia
  require Amnesia.Helper

  @doc """
  Find subnets those cidrs contains given IP address.
  """
  @spec get_subnets_for_ip(tuple) :: map() | []
  def get_subnets_for_ip(ip_address) do
    number_ip = CIDR.tuple2number(ip_address, 0)

    Amnesia.transaction(fn ->
      # This is solution.
      # 1. We use  :mnesia.select instead of Amnesia.Table.foldl
      # 2. We store CIDR not as structure but as two integer numbers
      :mnesia.select(DomainModel.Subnet, [
        {
          {:"$0", :"$1", :"$2", :"$3", :"$4", :"$5", :"$6", :"$7"},
          [
            # :first_number_ip and :last_number_ip is $5 and $6 fields accordingly
            make_and_mnesia_clause([
              {:"=<", :"$5", number_ip},
              {:>=, :"$6", number_ip}
            ])
          ],
          [:"$$"]
        }
      ])
    end)
    |> Enum.sort_by(fn [_, _, _, _, parsed_cidr, _, _, _] -> -1 * parsed_cidr.mask end)
    |> make_domain_model_table_records()
  end

  @doc """
  Gets ids list and variable name. And return IN clause for mnesia query.

  Examples:
  * DomainModelContext.make_in_mnesia_clause([], :"$1") #=> nil
  * DomainModelContext.make_in_mnesia_clause([1], :"$1") #=> {:==, name, 1}
  * DomainModelContext.make_in_mnesia_clause([1, 2], :"$1") #=> {:orelse, {:==, :"$1", 2}, {:==, :"$1", 1}}
  * DomainModelContext.make_in_mnesia_clause([1, 2, 3], :"$1") #=> {:orelse, {:==, :"$1", 3}, {:orelse, {:==, :"$1", 2}, {:==, :"$1", 1}}}
  """
  @spec make_in_mnesia_clause(list(integer), any) :: tuple
  def make_in_mnesia_clause(values_list, variable_name) when is_list(values_list) do
    Enum.reduce(values_list, nil, fn
      value, nil ->
        {:==, variable_name, value}

      value, clause ->
        {:orelse, {:==, variable_name, value}, clause}
    end)
  end

  @doc """
  Gets tuple and create new mnesia table record.
  """
  def make_domain_model_table_record(nil), do: nil

  def make_domain_model_table_record(attrs) when is_list(attrs) do
    attrs
    |> List.to_tuple()
    |> make_domain_model_table_record()
  end

  def make_domain_model_table_record(attrs) when is_tuple(attrs) do
    attrs
    |> DomainModel.make_table_record()
  end

  def make_domain_model_table_records(records) when is_list(records) do
    records
    |> Enum.map(fn record -> make_domain_model_table_record(record) end)
  end
end
