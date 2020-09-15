defmodule Web.AnalyticsLive do
  use Web, :live_view

  require Logger

  @impl true
  def render(assigns), do: Web.DashboardView.render("analytics.html", assigns)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Demo.PubSub, "AnalyticsService")

    socket =
      socket
      |> assign(:scheduled, 0)
      |> assign(:out_for_delivery, 0)
      |> assign(:shipment_count, 0)
      |> assign(:successfull_deliveries, 0)
      |> assign(:failed_deliveries, 0)
      |> fetch_all_events()

    {:ok, socket}
  end

  @impl true
  def handle_info(event_data, socket) do
    {:noreply, handle(event_data, socket)}
  end

  defp handle(%ShipmentRegistered{} = _event, socket) do
    update(socket, :shipment_count, &(&1 + 1))
  end

  defp handle(%ShipmentScheduled{} = _event, socket) do
    update(socket, :scheduled, &(&1 + 1))
  end

  defp handle(%ShipmentOutForDelivery{} = _event_data, socket) do
    socket
    |> update(:out_for_delivery, &(&1 + 1))
    |> update(:scheduled, &(&1 - 1))
  end

  defp handle(%ShipmentDelivered{} = %{delivered_successfully: true}, socket) do
    socket
    |> update(:successfull_deliveries, &(&1 + 1))
    |> update(:out_for_delivery, &(&1 - 1))
  end

  defp handle(%ShipmentDelivered{} = %{delivered_successfully: false}, socket) do
    socket
    |> update(:failed_deliveries, &(&1 + 1))
    |> update(:out_for_delivery, &(&1 - 1))
  end

  defp handle(_event, socket), do: socket

  defp fetch_all_events(socket) do
    Shared.EventStore.stream_all_forward()
    |> Enum.map(& &1.data)
    |> Enum.reduce(socket, &handle/2)
  end
end
