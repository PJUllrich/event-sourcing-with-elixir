defmodule Web.FleetLive.VehicleComponent do
  use Web, :live_component

  @impl true
  def render(assigns), do: Web.DashboardView.render("fleet/vehicle.html", assigns)

  @impl true
  def update(assigns, socket) do
    out_for_delivery =
      if is_nil(assigns[:out_for_delivery]), do: false, else: assigns[:out_for_delivery]

    vehicle =
      (socket.assigns[:vehicle] || assigns[:vehicle])
      |> Map.update!(:planned_shipment_count, &(assigns[:planned_shipment_count] || &1))
      |> Map.update!(
        :planned_shipment_count,
        &(&1 + (assigns[:planned_shipment_count_inc] || 0))
      )
      |> Map.put(:out_for_delivery, out_for_delivery)

    {:ok, assign(socket, :vehicle, vehicle)}
  end
end
