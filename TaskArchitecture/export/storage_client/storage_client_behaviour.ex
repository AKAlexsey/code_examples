defmodule TaskArchitecture.Services.Export.StorageClientBehaviour do
  @moduledoc """
  Describe common interface
  """

  alias TaskArchitecture.Exports.Export

  @callback write_to_storage(binary, binary, Export.t()) :: {:ok, binary} | {:error, any}

  @callback read_from_storage(binary, Export.t()) :: {:ok, binary} | {:error, any}

  @callback delete_from_storage(binary, Export.t()) :: {:ok, binary} | {:error, any}

  @callback write_main_file_to_storage(binary, binary) :: {:ok, binary} | {:error, any}

  @callback read_main_file_from_storage(binary) :: {:ok, binary} | {:error, any}
end
