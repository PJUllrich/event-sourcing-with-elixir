defmodule Web.TrackAndTraceLive do
  use Web, :live_view

  alias Web.TrackAndTraceLive.ShipmentComponent

  @impl true
  def render(assigns), do: Web.DashboardView.render("track_and_trace/index.html", assigns)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Demo.PubSub, "TrackAndTraceService")

    socket =
      socket
      |> fetch_shipments()
      |> fetch_all_events()

    {:ok, socket, temporary_assigns: [shipments: []]}
  end

  @impl true
  def handle_info(%ShipmentRegistered{} = event_data, socket) do
    shipment = create_shipment(event_data)
    socket = update(socket, :shipments, fn shipments -> [shipment | shipments] end)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%ShipmentOutForDelivery{} = %{shipment_id: shipment_id}, socket) do
    update_shipment(%{shipment_id: shipment_id, out_for_delivery: true})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%ShipmentDeliveredSuccessfully{} = %{shipment_id: shipment_id}, socket) do
    update_shipment(%{shipment_id: shipment_id, delivered_successfully: true})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%DeliveryFailed{} = %{shipment_id: shipment_id}, socket) do
    update_shipment(%{shipment_id: shipment_id, delivered_successfully: false})
    {:noreply, socket}
  end

  @impl true
  def handle_info(event_data, socket) do
    update_shipment(event_data)
    {:noreply, socket}
  end

  defp fetch_all_events(socket) do
    {:noreply, socket} =
      Shared.EventStore.stream_all_forward()
      |> Stream.filter(&(&1.event_type != "#{ShipmentRegistered}"))
      |> Enum.sort_by(& &1.created_at)
      |> Stream.map(& &1.data)
      |> Enum.reduce({:noreply, socket}, fn event_data, {:noreply, socket} ->
        handle_info(event_data, socket)
      end)

    socket
  end

  defp fetch_shipments(socket) do
    shipments =
      Shared.EventStore.stream_all_forward()
      |> Stream.filter(&(&1.event_type == "#{ShipmentRegistered}"))
      |> Stream.map(& &1.data)
      |> Stream.map(&create_shipment/1)
      |> Enum.sort_by(&String.to_integer(&1.shipment_id), :desc)

    assign(socket, :shipments, shipments)
  end

  defp create_shipment(event_data) do
    Map.merge(%Shipment{}, event_data)
  end

  defp update_shipment(%{shipment_id: shipment_id} = event_data) do
    send_update(ShipmentComponent, id: shipment_id, shipment: event_data)
  end

  defp update_shipment(_event_data), do: nil
end
