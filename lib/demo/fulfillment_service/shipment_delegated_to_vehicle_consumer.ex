defmodule FulfillmentService.ShipmentDelegatedToVehicleConsumer do
  use Shared.EventConsumer

  def handle(%ShipmentDelegatedToVehicle{} = event_data, state) do
    :ok = FulfillmentService.delegate_shipment_to_vehicle(event_data)
    {:ok, state}
  end
end
