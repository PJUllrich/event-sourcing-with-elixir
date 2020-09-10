defmodule State do
  defstruct [:shipments]
end

defmodule FulfillmentService.ShipmentRegisteredConsumer do
  use Shared.EventConsumer,
    initial_state: %State{shipments: []}

  def handle(%Demo.Events.ShipmentRegistered{} = shipment, %{shipments: shipments} = state) do
    {:ok, %{state | shipments: [shipment | shipments]}}
  end
end
