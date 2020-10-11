defmodule TaskArchitecture.Services.Export.ConvertToFileTest do
  use TaskArchitecture.DataCase

  alias TaskArchitecture.Exports.Export
  alias TaskArchitecture.Services.Export.ConvertToFile

  test "Return {:error, binary} if target type is unknown" do
    assert {:error, "Unknown Export type mistery"} =
             ConvertToFile.call(%Export{export_target_type: :mistery}, [])
  end
end
