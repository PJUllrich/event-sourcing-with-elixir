defmodule FleetService do
  use GenServer

  ###############################################################################################
  # Client API

  def start_link(opts \\ []) do
    out_for_deliver_delay = opts[:out_for_delivery_delay] || 2_000
    delivery_time = opts[:delivery_time] || 7_000

    vehicles = [
      %Vehicle{vehicle_id: "0", capacity: 1, planned_shipment_count: 0, out_for_delivery: false},
      %Vehicle{vehicle_id: "1", capacity: 2, planned_shipment_count: 0, out_for_delivery: false},
      %Vehicle{vehicle_id: "2", capacity: 3, planned_shipment_count: 0, out_for_delivery: false}
    ]

    opts =
      opts
      |> Keyword.merge(
        vehicles: vehicles,
        out_for_deliver_delay: out_for_deliver_delay,
        delivery_time: delivery_time
      )
      |> Map.new()

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def delegate_shipment_to_vehicle(shipment_id),
    do: GenServer.call(__MODULE__, {:delegate_shipment, shipment_id})

  ###############################################################################################
  # GenServer Callbacks

  def init(opts), do: {:ok, opts}

  def handle_call(
        {:delegate_shipment, shipment_id},
        _from,
        %{vehicles: vehicles} = opts
      ) do
    %{vehicle_id: vehicle_id} = vehicle = get_available_vehicle(vehicles)

    event = %ShipmentDelegatedToVehicle{
      shipment_id: shipment_id,
      vehicle_id: vehicle_id
    }

    vehicles =
      vehicle
      |> Map.update!(:planned_shipment_count, &(&1 + 1))
      |> update_vehicle(vehicles)

    if vehicle.capacity == vehicle.planned_shipment_count do
      Process.send_after(
        self(),
        {:vehicle_out_for_delivery, vehicle.vehicle_id},
        opts[:out_for_deliver_delay]
      )
    end

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: "FleetService"})
    Broadcaster.broadcast("FleetService", event)

    {:reply, :ok, %{opts | vehicles: vehicles}}
  end

  def handle_info({:vehicle_out_for_delivery, vehicle_id}, opts) do
    event = %VehicleOutForDelivery{vehicle_id: vehicle_id}

    opts = update_vehicle(vehicle_id, opts, :out_for_delivery, true)
    :ok = Shared.EventPublisher.publish(vehicle_id, event, %{enacted_by: "FleetService"})
    Broadcaster.broadcast("FleetService", event)

    Process.send_after(self(), {:vehicle_returned, vehicle_id}, opts[:delivery_time])
    {:noreply, opts}
  end

  def handle_info({:vehicle_returned, vehicle_id}, opts) do
    event = %VehicleReturned{vehicle_id: vehicle_id}

    opts = update_vehicle(vehicle_id, opts, :out_for_delivery, false)
    :ok = Shared.EventPublisher.publish(vehicle_id, event, %{enacted_by: "FleetService"})
    Broadcaster.broadcast("FleetService", event)

    {:noreply, opts}
  end

  ###############################################################################################
  # Private functions

  defp get_available_vehicle(vehicles) do
    vehicles
    |> Stream.filter(&(not &1.out_for_delivery))
    |> Enum.random()
  end

  defp update_vehicle(vehicle, vehicles) do
    Enum.map(vehicles, fn old_vehicle ->
      if old_vehicle.vehicle_id == vehicle.vehicle_id, do: vehicle, else: old_vehicle
    end)
  end

  defp update_vehicle(vehicle_id, %{vehicles: vehicles} = opts, key, new_value) do
    vehicles =
      vehicles
      |> Enum.find(&(&1.vehicle_id == vehicle_id))
      |> Map.put(key, new_value)
      |> update_vehicle(vehicles)

    %{opts | vehicles: vehicles}
  end
end