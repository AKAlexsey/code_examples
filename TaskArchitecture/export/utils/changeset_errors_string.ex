defmodule TaskArchitecture.Common.ChangesetErrorsString do
  @moduledoc """
  Simple module of one useful helper to generate meaningful errors string for
  Ecto changesets
  """
  def errors_string(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
    |> Enum.join("; ")
  end
end
