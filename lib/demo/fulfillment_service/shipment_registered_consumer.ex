defmodule FulfillmentService.ShipmentRegisteredConsumer do
  use Shared.EventConsumer

  def handle(%ShipmentRegistered{} = %{shipment_id: shipment_id}, state) do
    FulfillmentService.schedule_shipment(shipment_id)
    {:ok, state}
  end
end
