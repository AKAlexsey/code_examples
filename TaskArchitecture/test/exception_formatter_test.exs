defmodule TaskArchitecture.Common.ExceptionFormatterTest do
  use TaskArchitecture.DataCase
  alias TaskArchitecture.Common.ExceptionFormatter

  setup do
    {:ok,
     error: %RuntimeError{message: "Error"},
     stacktrace: [
       {TaskArchitecture.Common.ExceptionFormatterTest,
        :"test #format_error Format error with stacktrace", 1,
        [file: 'test/common/exception_formatter_test.exs', line: 7]},
       {ExUnit.Runner, :exec_test, 1, [file: 'lib/ex_unit/runner.ex', line: 355]},
       {:timer, :tc, 1, [file: 'timer.erl', line: 166]},
       {ExUnit.Runner, :"-spawn_test_monitor/4-fun-1-", 4,
        [file: 'lib/ex_unit/runner.ex', line: 306]}
     ],
     banner_error_standard: """
     ** (RuntimeError) Error
         test/common/exception_formatter_test.exs:7: TaskArchitecture.Common.ExceptionFormatterTest.\"test #format_error Format error with stacktrace\"/1
         (ex_unit) lib/ex_unit/runner.ex:355: ExUnit.Runner.exec_test/1
         (stdlib) timer.erl:166: :timer.tc/1
         (ex_unit) lib/ex_unit/runner.ex:306: anonymous fn/4 in ExUnit.Runner.spawn_test_monitor/4
     """}
  end

  describe "#format_error" do
    test "Format error with stacktrace",
         %{error: error, stacktrace: stacktrace, banner_error_standard: banner_error_standard} do
      assert banner_error_standard == ExceptionFormatter.format_error(error, stacktrace)
    end
  end

  describe "#make_error_message" do
    test "Perform full inspect if string is very long" do
      result = ExceptionFormatter.make_error_message(String.duplicate("12345", 2000))
      assert String.length(result) == 10_002
    end

    test "Format banner if error tuple is given",
         %{error: error, stacktrace: stacktrace, banner_error_standard: banner_error_standard} do
      assert banner_error_standard == ExceptionFormatter.make_error_message({error, stacktrace})
    end
  end
end
