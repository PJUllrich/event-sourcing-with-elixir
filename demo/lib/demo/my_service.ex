defmodule Demo.MyService do
  alias Demo.Events.ShipmentRegistered

  def create_shipment(id) do
    # Persist new Shipment in Database
    # e.g. Repo.insert(%Shipment{id: id})
    event = %ShipmentRegistered{with_id: id}
    Shared.EventPublisher.publish("#shipment-#{id}", event, %{enacted_by: "peter.ullrich"})
  end
end
