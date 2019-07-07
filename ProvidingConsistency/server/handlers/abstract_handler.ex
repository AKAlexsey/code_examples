# Common interface for interaction between different components
defmodule ExampleProject.Handlers.AbstractHandler do
  @moduledoc """
  Behaviour for handlers
  """

  @callback handle(event :: atom, params :: map) :: {:ok, term} | :ok | {:error, String.t()}
end
