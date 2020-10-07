defmodule Demo.EventConsumer do
  use Shared.EventConsumer

  alias Demo.Events.ShipmentRegistered

  def handle(%ShipmentRegistered{} = event_data, %{metadata: metadata}) do
    IO.inspect(event_data, label: "Demo.EventConsumer received Event")
    IO.inspect(metadata, label: "Demo.EventConsumer received Metadata")

    :ok
  end
end
