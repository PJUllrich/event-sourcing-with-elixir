defmodule Shipment do
  defstruct [
    :shipment_id,
    :destination,
    :delivered_successfully,
    :out_for_delivery,
    :scheduled_for
  ]
end
