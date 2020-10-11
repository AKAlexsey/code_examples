defmodule TaskArchitecture.Common.Utils do
  @moduledoc """
  Contains helper functions that can't be related to any context
  """

  @doc """
  Safe merge url and query. Concat query params if url have it.

   ## Examples

      iex> merge_url_and_query("http://google.ru", "utm_source=utm")
      "http://google.ru?utm_source=utm"

      iex> merge_url_and_query("http://google.ru?utm_campaign=campaign", "utm_source=url")
      "http://google.ru?utm_campaign=campaign&utm_source=utm"
  """
  @spec merge_url_and_query(binary, binary) :: binary
  def merge_url_and_query(url, query) do
    parsed_url = URI.parse(url)
    parsed_query = URI.parse(query)

    parsed_url
    |> Map.merge(parsed_query, fn
      :query, v1, v2 ->
        [v1, v2]
        |> Enum.filter(&(not is_nil(&1)))
        |> Enum.join("&")

      _key, v1, _v2 ->
        v1
    end)
    |> to_string()
  end

  @doc """
  Capitalize and replace "_" with " ". Accepts binary or atom.
  """
  @spec humanize_string(binary | atom) :: binary
  def humanize_string(name) do
    "#{name}"
    |> String.capitalize()
    |> String.replace("_", " ")
  end

  @iso_time_format "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}.000Z"

  @doc """
  Convert time to the acceptable
  """
  @spec job_board_time_format(NaiveDateTime.t() | DateTime.t()) :: binary
  def job_board_time_format(%NaiveDateTime{} = date_time) do
    Timex.format!(date_time, @iso_time_format)
  end

  def job_board_time_format(%DateTime{} = date_time) do
    Timex.format!(date_time, @iso_time_format)
  end

  @doc """
  Inspect any value without length restriction
  """
  @spec full_inspect(any) :: String.t()
  def full_inspect(value) do
    inspect(value, limit: :infinity, printable_limit: :infinity)
  end

  @spec safe_to_integer(integer | binary) :: integer
  def safe_to_integer(value) when is_binary(value) do
    String.to_integer(value)
  end

  def safe_to_integer(value), do: value

  @spec changeset_error_to_string(Ecto.Changeset.t()) :: binary
  def changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> stringify_errors()
  end

  @spec stringify_errors(map) :: binary
  defp stringify_errors(errors) when is_map(errors) do
    errors
    |> Enum.map(fn
      {k, v} when is_map(v) ->
        joined_errors = stringify_errors(v)
        "#{k}: [#{joined_errors}]"

      {k, v} ->
        joined_errors = Enum.join(v, ", ")
        "#{k}: #{joined_errors}"
    end)
    |> Enum.join("; ")
  end
end
