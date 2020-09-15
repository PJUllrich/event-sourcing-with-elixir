defmodule Web.OrdersLive do
  use Web, :live_view

  @impl true
  def render(assigns), do: Web.DashboardView.render("orders.html", assigns)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Demo.PubSub, "OrderService")

    socket =
      socket
      |> assign(:shipments, socket.assigns[:shipments] || [])
      |> fetch_all_events()

    {:ok, socket}
  end

  @impl true
  def handle_info(event_data, socket) do
    {:noreply, handle(event_data, socket)}
  end

  defp handle(
         %ShipmentRegistered{} = %{shipment_id: shipment_id, destination: destination},
         socket
       ) do
    shipment = %Shipment{shipment_id: shipment_id, destination: destination}
    update(socket, :shipments, fn shipments -> [shipment | shipments] end)
  end

  defp handle(_event, socket), do: socket

  defp fetch_all_events(socket) do
    Shared.EventStore.stream_all_forward()
    |> Enum.map(& &1.data)
    |> Enum.reduce(socket, &handle/2)
  end
end
