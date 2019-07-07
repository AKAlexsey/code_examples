# Route incoming data to appropriate Mnesia table handler.

defmodule ExampleProject.Handlers.DomainModelHandler do
  alias ExampleProject.Handlers.AbstractHandler

  alias ExampleProject.DomainModelHandlers.{
    LinearChannelHandler,
    ProgramHandler,
    ProgramRecordHandler,
    RegionHandler,
    ServerGroupHandler,
    ServerHandler, # This handler is only inside example others left for demonstration destination of this module
    SubnetHandler,
    TvStreamHandler
  }

  @behaviour AbstractHandler

  def handle(action, %{model_name: "Program", attrs: attrs}) do
    ProgramHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "ProgramRecord", attrs: attrs}) do
    ProgramRecordHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "Region", attrs: attrs}) do
    RegionHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "ServerGroup", attrs: attrs}) do
    ServerGroupHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "Server", attrs: attrs}) do
    ServerHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "Subnet", attrs: attrs}) do
    SubnetHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "LinearChannel", attrs: attrs}) do
    LinearChannelHandler.handle(action, attrs)
    :ok
  end

  def handle(action, %{model_name: "TvStream", attrs: attrs}) do
    TvStreamHandler.handle(action, attrs)
    :ok
  end

  def handle(event, %{model_name: name, attrs: attrs}) do
    raise "ExampleProject.Handlers.DomainModelHandler unknown model name #{inspect(name)} event: #{
            event
          } attrs #{inspect(attrs)}"

    :ok
  end
end
