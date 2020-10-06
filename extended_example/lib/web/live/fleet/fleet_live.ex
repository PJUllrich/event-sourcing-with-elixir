defmodule Web.FleetLive do
  use Web, :live_view

  require Logger

  alias Web.FleetLive.VehicleComponent

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
  def handle_info(%ShipmentDelegatedToVehicle{} = %{vehicle_id: vehicle_id}, socket) do
    send_update(VehicleComponent, id: vehicle_id, planned_shipment_count_inc: 1)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%VehicleOutForDelivery{} = %{vehicle_id: vehicle_id}, socket) do
    send_update(VehicleComponent, id: vehicle_id, out_for_delivery: true)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%VehicleReturned{} = %{vehicle_id: vehicle_id}, socket) do
    send_update(VehicleComponent,
      id: vehicle_id,
      planned_shipment_count: 0,
      out_for_delivery: false
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp fetch_all_events(socket) do
    {:noreply, socket} =
      Shared.EventStore.stream_all_forward()
      |> Enum.sort_by(& &1.created_at)
      |> Enum.map(& &1.data)
      |> Enum.reduce({:noreply, socket}, fn event_data, {:noreply, socket} ->
        handle_info(event_data, socket)
      end)

    socket
  end
end
