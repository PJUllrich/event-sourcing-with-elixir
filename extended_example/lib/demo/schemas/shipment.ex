defmodule Shipment do
  defstruct [
    :shipment_id,
    :destination,
    :delivered_successfully,
    :out_for_delivery,
    :delivering_vehicle,
    :scheduled_for_vehicle,
    :scheduled_for
  ]
end
