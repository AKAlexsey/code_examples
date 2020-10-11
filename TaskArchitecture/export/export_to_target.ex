defmodule TaskArchitecture.Services.Export.ExportToTarget do
  @moduledoc """
  Convert given Export configuration into Target configuration and fetch all records for given company.
  """

  alias TaskArchitecture.Configurations.{Target, TargetEmbed}
  alias TaskArchitecture.Exports.{Company, Export}

  @spec perform(Company, Export.t()) :: {:ok, list(Target.t())} | {:error, binary}
  def perform(%Company{} = company, %Export{}) do
    case company do
      %Company{
        organization_reference: reference,
        access_token: access_token,
        apec_manual_fields: %{limitation_rules: limitation_rules}
      }
      when is_binary(reference) and reference != "" and is_binary(access_token) and
             access_token != "" ->
        {:ok,
         %Target{
           config: %TargetEmbed{
             access_token: access_token,
             organization_reference: reference,
             limitation_rules: limitation_rules
           }
         }}

      _ ->
        {:error, "Company does not have organization_reference or access_token"}
    end
  end

  def perform(first_argument, second_argument) do
    {:error, "Invalid arguments: #{inspect(first_argument)}, #{inspect(second_argument)}"}
  end
end
