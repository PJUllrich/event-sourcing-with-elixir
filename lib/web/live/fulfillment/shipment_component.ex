defmodule Web.FulfillmentLive.ShipmentComponent do
  use Web, :live_component

  @impl true
  def render(assigns), do: Web.DashboardView.render("fulfillment/shipment.html", assigns)

  @impl true
  def update(assigns, socket) do
    old_shipment = socket.assigns[:shipment] || %Shipment{}
    update = assigns[:shipment] || %{}
    shipment = Map.merge(old_shipment, update)

    {:ok, assign(socket, :shipment, shipment)}
  end
end
