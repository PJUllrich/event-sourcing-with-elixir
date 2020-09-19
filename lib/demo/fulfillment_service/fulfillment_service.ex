defmodule FulfillmentService do
  use GenServer

  ###############################################################################################
  # Client API

  def start_link(opts \\ []) do
    fulfillment_delay = opts[:fulfillment_delay] || 5_000
    delivery_delay = opts[:delivery_delay] || 10_000
    scheduling_delay = opts[:scheduling_delay] || 1_000

    opts =
      opts
      |> Keyword.merge(
        fulfillment_delay: fulfillment_delay,
        delivery_delay: delivery_delay,
        scheduling_delay: scheduling_delay,
        shipment_delegations: %{}
      )
      |> Map.new()

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_shipment(shipment_id),
    do: GenServer.call(__MODULE__, {:schedule_shipment, shipment_id})

  def delegate_shipment_to_vehicle(event_data) do
    GenServer.call(__MODULE__, {:delegate_shipment, event_data})
  end

  def mark_shipments_as_out_for_delivery_for_vehicle(vehicle_id) do
    GenServer.call(__MODULE__, {:mark_shimpents_as_out_for_delivery, vehicle_id})
  end

  ###############################################################################################
  # GenServer Callbacks

  def init(opts), do: {:ok, opts}

  def handle_call({:schedule_shipment, shipment_id}, _from, opts) do
    Process.send_after(self(), {:schedule_shipment, shipment_id}, opts[:scheduling_delay])
    {:reply, :ok, opts}
  end

  def handle_call(
        {:mark_shimpents_as_out_for_delivery, vehicle_id},
        _from,
        %{shipment_delegations: shipment_delegations} = opts
      ) do
    shipment_ids = Map.get(shipment_delegations, vehicle_id, [])

    for shipment_id <- shipment_ids do
      event = %ShipmentOutForDelivery{shipment_id: shipment_id, vehicle_id: vehicle_id}

      :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: __MODULE__})
      Broadcaster.broadcast("FulfillmentService", event)

      Process.send_after(
        self(),
        {:shipment_delivered, shipment_id},
        :rand.uniform(opts[:delivery_delay])
      )
    end

    shipment_delegations = Map.put(shipment_delegations, vehicle_id, [])

    {:reply, :ok, %{opts | shipment_delegations: shipment_delegations}}
  end

  def handle_call(
        {:delegate_shipment, %{shipment_id: shipment_id, vehicle_id: vehicle_id} = event_data},
        _from,
        %{shipment_delegations: shipment_delegations} = opts
      ) do
    shipment_delegations =
      Map.update(shipment_delegations, vehicle_id, [], fn shipment_ids ->
        [shipment_id | shipment_ids]
      end)

    Broadcaster.broadcast("FulfillmentService", event_data)

    {:reply, :ok, %{opts | shipment_delegations: shipment_delegations}}
  end

  def handle_info({:schedule_shipment, shipment_id}, opts) do
    event = %ShipmentScheduledForDelivery{
      shipment_id: shipment_id,
      scheduled_for: gen_scheduled_time(opts)
    }

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: __MODULE__})
    Broadcaster.broadcast("FulfillmentService", event)

    {:noreply, opts}
  end

  def handle_info({:shipment_delivered, shipment_id}, opts) do
    event =
      if Enum.random([true, true, true, false]) do
        %ShipmentDeliveredSuccessfully{shipment_id: shipment_id}
      else
        %DeliveryFailed{shipment_id: shipment_id}
      end

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: __MODULE__})
    Broadcaster.broadcast("FulfillmentService", event)

    {:noreply, opts}
  end

  ###############################################################################################
  # Private functions

  defp gen_scheduled_time(%{fulfillment_delay: fulfillment_delay}) do
    DateTime.now!("Europe/Berlin")
    |> DateTime.to_time()
    |> Time.add(fulfillment_delay, :millisecond)
  end
end
