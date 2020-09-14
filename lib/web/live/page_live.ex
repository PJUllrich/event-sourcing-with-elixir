defmodule Shipment do
  defstruct [
    :shipment_id,
    :destination,
    :delivered_successfully,
    :out_for_delivery,
    :scheduled_for
  ]
end

defmodule Web.PageLive do
  use Web, :live_view

  @impl true
  def render(assigns), do: Web.PageView.render("index.html", assigns)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Demo.PubSub, "TrackAndTraceService")
    {:ok, socket, temporary_assigns: [shipments: []]}
  end

  @impl true
  def handle_info(
        %ShipmentRegistered{} = %{shipment_id: shipment_id, destination: destination},
        socket
      ) do
    shipment = %Shipment{shipment_id: shipment_id, destination: destination}
    {:noreply, update(socket, :shipments, fn shipments -> [shipment | shipments] end)}
  end

  @impl true
  def handle_info(%ShipmentScheduled{} = _event, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%ShipmentOutForDelivery{} = _event, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%ShipmentDelivered{} = _event, socket) do
    {:noreply, socket}
  end
end
