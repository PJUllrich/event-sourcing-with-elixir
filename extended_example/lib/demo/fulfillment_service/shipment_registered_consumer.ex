defmodule FulfillmentService.ShipmentRegisteredConsumer do
  use Shared.EventConsumer

  def handle(%ShipmentRegistered{} = event_data, state) do
    FulfillmentService.schedule_shipment(event_data.shipment_id)
    Broadcaster.broadcast("FulfillmentService", event_data)
    {:ok, state}
  end
end
