defmodule FleetService.ShipmentScheduledForDeliveryConsumer do
  use Shared.EventConsumer

  def handle(%ShipmentScheduledForDelivery{} = %{shipment_id: shipment_id}, state) do
    FleetService.delegate_shipment_to_vehicle(shipment_id)
    {:ok, state}
  end
end
