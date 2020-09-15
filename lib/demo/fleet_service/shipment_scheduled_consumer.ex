defmodule FleetService.ShipmentScheduledConsumer do
  use Shared.EventConsumer

  def handle(%ShipmentScheduled{} = %{shipment_id: shipment_id}, state) do
    FleetService.delegate_shipment_to_vehicle(shipment_id)
    {:ok, state}
  end
end
