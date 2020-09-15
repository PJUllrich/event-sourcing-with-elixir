defmodule Web.FulfillmentLive do
  use Web, :live_view

  @impl true
  def render(assigns), do: Web.DashboardView.render("fulfillment/index.html", assigns)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Demo.PubSub, "FulfillmentService")

    socket =
      socket
      |> fetch_shipments()
      |> fetch_all_events()

    {:ok, socket, temporary_assigns: [shipments: []]}
  end

  @impl true
  def handle_info(event_data, socket) do
    {:noreply, handle(event_data, socket)}
  end

  defp handle(
         %ShipmentRegistered{} = event_data,
         socket
       ) do
    shipment = create_shipment(event_data)
    update(socket, :shipments, fn shipments -> [shipment | shipments] end)
  end

  defp handle(%ShipmentOutForDelivery{} = event_data, socket) do
    update_shipment(Map.merge(event_data, %{out_for_delivery: true}), socket)
  end

  defp handle(event_data, socket), do: update_shipment(event_data, socket)

  defp fetch_all_events(socket) do
    Shared.EventStore.stream_all_forward()
    |> Stream.filter(&(&1.event_type != "#{ShipmentRegistered}"))
    |> Enum.map(& &1.data)
    |> Enum.reduce(socket, &handle/2)
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

  defp update_shipment(
         %{shipment_id: shipment_id} = event_data,
         socket
       ) do
    send_update(Web.FulfillmentLive.ShipmentComponent,
      id: shipment_id,
      shipment: event_data
    )

    socket
  end
end
