defmodule TaskArchitecture.Services.ExportJobRecordsCleaner do
  @moduledoc """
  Remove all ExportJob that has been created before given number of seconds.
  """

  alias TaskArchitecture.Exports
  import JobsImporterWeb.DisplayDatetimeHelpers, only: [display_datetime: 1]

  require Logger

  @cleanup_seconds_ago Application.get_env(:jobs_importer, __MODULE__)[:cleanup_seconds_ago]

  @doc """
  Remove all ImportJob before given amount in seconds in the past from now.
  """
  def perform(cleanup_seconds_ago \\ @cleanup_seconds_ago) do
    now = NaiveDateTime.utc_now()
    cleanup_time = NaiveDateTime.add(now, -cleanup_seconds_ago)

    Logger.info(
      "#{__MODULE__} Starting cleaning up #{display_datetime(now)}, cleanup ExportJob before #{
        display_datetime(cleanup_time)
      }"
    )

    result = Exports.remove_export_job_before(cleanup_time)
    Logger.info("#{__MODULE__} Cleaning up successfully finished. Result #{inspect(result)}.")
  end
end
