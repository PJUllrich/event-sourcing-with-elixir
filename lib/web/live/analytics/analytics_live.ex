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
  def handle_info(%ShipmentRegistered{} = _event, socket) do
    {:noreply, update(socket, :shipment_count, &(&1 + 1))}
  end

  @impl true
  def handle_info(%ShipmentScheduledForDelivery{} = _event, socket) do
    {:noreply, update(socket, :scheduled, &(&1 + 1))}
  end

  @impl true
  def handle_info(%ShipmentOutForDelivery{} = _event_data, socket) do
    socket =
      socket
      |> update(:out_for_delivery, &(&1 + 1))
      |> update(:scheduled, &(&1 - 1))

    {:noreply, socket}
  end

  @impl true
  def handle_info(%ShipmentDeliveredSuccessfully{} = _event, socket) do
    socket =
      socket
      |> update(:successfull_deliveries, &(&1 + 1))
      |> update(:out_for_delivery, &(&1 - 1))

    {:noreply, socket}
  end

  @impl true
  def handle_info(%DeliveryFailed{} = _event, socket) do
    socket =
      socket
      |> update(:failed_deliveries, &(&1 + 1))
      |> update(:out_for_delivery, &(&1 - 1))

    {:noreply, socket}
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp fetch_all_events(socket) do
    {:noreply, socket} =
      Shared.EventStore.stream_all_forward()
      |> Enum.map(& &1.data)
      |> Enum.reduce({:noreply, socket}, fn event_data, {:noreply, socket} ->
        handle_info(event_data, socket)
      end)

    socket
  end
end
