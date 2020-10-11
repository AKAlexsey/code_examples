defmodule TaskArchitecture.Common.UtilsTest do
  use TaskArchitecture.DataCase
  alias TaskArchitecture.Common.Utils

  describe "#merge_url_and_query" do
    test "Merge URL and query if uri doesn't have query params" do
      assert "http://google.ru?utm_source=url" =
               Utils.merge_url_and_query("http://google.ru", "?utm_source=url")
    end

    test "Merge URL and query if uri have anchor in the end" do
      assert "http://google.ru?utm_source=url#anchor" =
               Utils.merge_url_and_query("http://google.ru#anchor", "?utm_source=url")
    end

    test "Merge URL and query if uri has query params" do
      assert "http://google.ru?utm_campaign=campaign&utm_source=url" =
               Utils.merge_url_and_query(
                 "http://google.ru?utm_campaign=campaign",
                 "?utm_source=url"
               )
    end

    test "Left only query params if full uri given as second argument" do
      assert "http://google.ru?utm_campaign=campaign&utm_source=url" =
               Utils.merge_url_and_query(
                 "http://google.ru?utm_campaign=campaign",
                 "http://coub.com?utm_source=url"
               )
    end
  end

  describe "#job_board_time_format" do
    test "Convert to the right format" do
      naive_date_time = NaiveDateTime.from_erl!({{2017, 1, 1}, {1, 1, 1}})
      standard_result = "2017-01-01T01:01:01.000Z"
      assert standard_result == Utils.job_board_time_format(naive_date_time)

      date_time = DateTime.from_naive!(naive_date_time, "Etc/UTC")

      assert standard_result == Utils.job_board_time_format(date_time)
    end
  end

  describe "#full_inspect" do
    test "Inspect string without limitations" do
      very_long_string = String.duplicate("asc ", 2000)

      assert String.length(Utils.full_inspect(very_long_string)) == 8002
      assert String.length(Utils.full_inspect(%{keyk: very_long_string})) == 8011
    end
  end
end
