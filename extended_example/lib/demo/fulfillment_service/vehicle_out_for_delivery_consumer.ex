defmodule FulfillmentService.VehicleOutForDeliveryConsumer do
  use Shared.EventConsumer

  def handle(%VehicleOutForDelivery{} = %{vehicle_id: vehicle_id}, state) do
    :ok = FulfillmentService.mark_shipments_as_out_for_delivery_for_vehicle(vehicle_id)
    {:ok, state}
  end
end
