defmodule FleetService do
  use GenServer

  ###############################################################################################
  # Client API

  def start_link(opts \\ []) do
    delivery_time = opts[:delivery_time] || 10_000

    vehicles = [
      %Vehicle{vehicle_id: "1", capacity: 2, planned_shipment_count: 0, out_for_delivery: false},
      %Vehicle{vehicle_id: "2", capacity: 2, planned_shipment_count: 0, out_for_delivery: false},
      %Vehicle{vehicle_id: "3", capacity: 2, planned_shipment_count: 0, out_for_delivery: false}
    ]

    opts =
      opts
      |> Keyword.merge(
        vehicles: vehicles,
        delivery_time: delivery_time
      )
      |> Map.new()

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def delegate_shipment_to_vehicle(shipment_id),
    do: GenServer.call(__MODULE__, {:delegate_shipment, shipment_id})

  def list_vehicles(), do: GenServer.call(__MODULE__, :list_vehicles)

  ###############################################################################################
  # GenServer Callbacks

  def init(opts), do: {:ok, opts}

  def handle_call(:list_vehicles, _from, %{vehicles: vehicles} = opts),
    do: {:reply, vehicles, opts}

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

    updated_vehicle = Map.update!(vehicle, :planned_shipment_count, &(&1 + 1))

    vehicles = update_vehicle(updated_vehicle, vehicles)

    :ok = Shared.EventPublisher.publish(shipment_id, event, %{enacted_by: "FleetService"})
    Broadcaster.broadcast("FleetService", event)

    if updated_vehicle.capacity <= updated_vehicle.planned_shipment_count do
      send(self(), {:vehicle_out_for_delivery, updated_vehicle.vehicle_id})
    end

    {:reply, :ok, %{opts | vehicles: vehicles}}
  end

  def handle_info({:vehicle_out_for_delivery, vehicle_id}, opts) do
    event = %VehicleOutForDelivery{vehicle_id: vehicle_id}

    opts = update_vehicle(vehicle_id, opts, %{out_for_delivery: true})
    :ok = Shared.EventPublisher.publish(vehicle_id, event, %{enacted_by: "FleetService"})
    Broadcaster.broadcast("FleetService", event)

    Process.send_after(self(), {:vehicle_returned, vehicle_id}, opts[:delivery_time])
    {:noreply, opts}
  end

  def handle_info({:vehicle_returned, vehicle_id}, opts) do
    event = %VehicleReturned{vehicle_id: vehicle_id}

    opts = update_vehicle(vehicle_id, opts, %{out_for_delivery: false, planned_shipment_count: 0})
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

  defp update_vehicle(vehicle_id, %{vehicles: vehicles} = opts, attrs) do
    vehicles =
      vehicles
      |> Enum.find(&(&1.vehicle_id == vehicle_id))
      |> Map.merge(attrs)
      |> update_vehicle(vehicles)

    %{opts | vehicles: vehicles}
  end
end
