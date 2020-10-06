defmodule Demo.EventConsumer do
  use Shared.EventConsumer

  alias Demo.Events.ShipmentRegistered

  def handle(%ShipmentRegistered{} = event_data, state) do
    IO.inspect(event_data, label: "Demo.EventConsumer received Event")
    {:ok, state}
  end
end
