## Protocol for serializing record data to map.
## Common interface for all models.
defprotocol ExampleProject.Protocols.NotifyServerAttrs do
  @doc ""
  @spec get(data :: map()) :: map()
  def get(record)
end
