defmodule TaskArchitecture.Changeset.AttrsNormalizer do
  @moduledoc """
  Prepare attrs according to given configurations.
  Configurations is map that looks like:

  ```
  %{
    field: &String.to_integer()
  }
  ```
  """

  @integer_regex ~r/^\d+$/

  @doc """
  Perform validation for each field by given configuration. If there is no configuration left value like it was.
  Atomize keys.
  """
  @spec normalize(map, map) :: map
  def normalize(%{} = attrs, %{} = configuration \\ %{}) do
    attrs
    |> Enum.map(fn {key, value} ->
      atom_key = atomize_key(key)

      case Map.get(configuration, atom_key) do
        nil -> {atom_key, value}
        value_function -> {atom_key, value_function.(value)}
      end
    end)
    |> Enum.into(%{})
  end

  @spec atomize_key(atom | binary) :: atom
  def atomize_key(value) when is_atom(value), do: value
  def atomize_key(value) when is_binary(value), do: String.to_existing_atom(value)

  @doc """
  Accept binary or integer value. Move binary to integer.
  If binary is doesn't match `^\\d+$` regex. Return nil.
  """
  @spec string_to_integer(any) :: integer | nil | any
  def string_to_integer(value) when is_binary(value) do
    case Regex.run(@integer_regex, value) do
      [valid_string] ->
        String.to_integer(valid_string)

      _ ->
        nil
    end
  end

  def string_to_integer(value), do: value

  @doc """
  Accept binary or integer value. Move binary to integer.
  If binary is doesn't match `^\\d+$` regex. Return nil.
  """
  @spec string_to_atom(any) :: atom | any
  def string_to_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  end

  def string_to_atom(value), do: value

  @doc """
  Split given string by separator (Second argument. "," by default) and move it to array.
  If argument is not string pass further without any changes.
  """
  @spec string_to_array(any, binary) :: list()
  def string_to_array(value, separator \\ ",")

  def string_to_array("", _separator), do: []

  def string_to_array(value, separator) when is_binary(value),
    do: String.split(value, separator)

  def string_to_array(value, _separator), do: value
end
