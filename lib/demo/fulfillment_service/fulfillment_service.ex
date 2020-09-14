defmodule FulfillmentService do
  use GenServer

  ###############################################################################################
  # Client API

  def start_link(opts \\ []) do
    fulfillment_delay = opts[:fulfillment_delay] || 5_000
    delivery_delay = opts[:delivery_delay] || 3_000

    opts =
      opts
      |> Keyword.merge(fulfillment_delay: fulfillment_delay, delivery_delay: delivery_delay)
      |> Map.new()

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_shipment(shipment_id),
    do: GenServer.call(__MODULE__, {:schedule_shipment, shipment_id})

  ###############################################################################################
  # GenServer Callbacks

  def init(opts), do: {:ok, opts}

  def handle_call({:schedule_shipment, shipment_id}, _from, opts) do
    event = %ShipmentScheduled{
      shipment_id: shipment_id,
      scheduled_for: Time.utc_now() |> Time.add(opts[:fulfillment_delay])
    }

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: __MODULE__})

    Process.send_after(self(), {:out_for_delivery, shipment_id}, opts[:fulfillment_delay])
    {:reply, :ok, opts}
  end

  def handle_info({:out_for_delivery, shipment_id}, opts) do
    event = %ShipmentOutForDelivery{shipment_id: shipment_id}

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: __MODULE__})
    broadcast("ShipmentOutForDelivery", event)

    Process.send_after(
      self(),
      {:shipment_delivered, shipment_id},
      opts[:delivery_delay]
    )

    {:noreply, opts}
  end

  def handle_info({:shipment_delivered, shipment_id}, opts) do
    event = %ShipmentDelivered{
      shipment_id: shipment_id,
      delivered_successfully: Enum.random([true, true, true, false])
    }

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: __MODULE__})
    broadcast("ShipmentDelivered", event)

    {:noreply, opts}
  end

  defp broadcast(topic, event) do
    Phoenix.PubSub.broadcast_from!(
      Demo.PubSub,
      self(),
      "FulfillmentService." <> topic,
      event
    )
  end
end
