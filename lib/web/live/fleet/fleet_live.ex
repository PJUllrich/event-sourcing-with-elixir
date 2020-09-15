defmodule Web.FleetLive do
  use Web, :live_view

  require Logger

  @impl true
  def render(assigns), do: Web.DashboardView.render("fleet/index.html", assigns)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Demo.PubSub, "FleetService")

    socket =
      socket
      |> assign(:vehicles, FleetService.list_vehicles())
      |> fetch_all_events()

    {:ok, socket}
  end

  @impl true
  def handle_info(event_data, socket) do
    {:noreply, handle(event_data, socket)}
  end

  defp handle(%ShipmentDelegatedToVehicle{} = %{vehicle_id: vehicle_id}, socket) do
    send_update(Web.FleetLive.VehicleComponent, id: vehicle_id, planned_shipment_count_inc: 1)
    socket
  end

  defp handle(%VehicleOutForDelivery{} = %{vehicle_id: vehicle_id}, socket) do
    send_update(Web.FleetLive.VehicleComponent, id: vehicle_id, out_for_delivery: true)
    socket
  end

  defp handle(%VehicleReturned{} = %{vehicle_id: vehicle_id}, socket) do
    send_update(Web.FleetLive.VehicleComponent,
      id: vehicle_id,
      planned_shipment_count: 0,
      out_for_delivery: false
    )

    socket
  end

  defp handle(_event, socket), do: socket

  defp fetch_all_events(socket) do
    Shared.EventStore.stream_all_forward()
    |> Enum.sort_by(& &1.created_at)
    |> Enum.map(& &1.data)
    |> Enum.reduce(socket, &handle/2)
  end
end
