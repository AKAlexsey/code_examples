defmodule TaskArchitecture.Services.Export.ExportCompaniesFetcher do
  @moduledoc """
  Concurrently fetch job offers according to the configurations given as peremeter
  """

  alias TaskArchitecture.Exports
  alias TaskArchitecture.Exports.{Company, Export}

  @spec call(list) :: {:ok, {list(tuple), list(tuple)}} | {:error, binary}
  def call(%Export{companies: []}), do: {:error, "Export has no companies"}

  def call(%Export{companies: %Ecto.Association.NotLoaded{}}),
    do: {:error, "Companies are not preloaded"}

  def call(%Export{companies: companies_list})
      when is_list(companies_list) and companies_list != [] do
    companies_list
    |> Enum.reduce({[], []}, fn %Company{} = company, {success, failed} ->
      company
      |> Exports.validate_company()
      |> case do
        :ok ->
          {[company] ++ success, failed}

        {:error, reason} ->
          {success, [{company, reason}] ++ failed}
      end
    end)
    |> (fn result -> {:ok, result} end).()
  end
end
