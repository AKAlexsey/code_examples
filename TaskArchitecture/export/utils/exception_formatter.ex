defmodule TaskArchitecture.Common.ExceptionFormatter do
  @moduledoc """
  Perform generic way to format exception errors with stacktrace
  """

  alias TaskArchitecture.Common.Utils

  @spec format_error(any, list) :: binary
  def format_error(error, stacktrace \\ []) do
    error = Exception.format_banner(:error, error)

    stacktrace =
      if is_list(stacktrace) do
        Exception.format_stacktrace(stacktrace)
      else
        "Weird stacktrace: #{Exception.format_banner(:error, stacktrace)}"
      end

    "#{error}\n#{stacktrace}"
  end

  @spec make_error_message(any) :: binary
  def make_error_message(error) do
    case error do
      {error_itself, stacktrace} ->
        format_error(error_itself, stacktrace)

      _ ->
        Utils.full_inspect(error)
    end
  end
end
