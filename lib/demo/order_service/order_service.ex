defmodule Demo.OrderService do
  use GenServer

  alias ShipmentRegistered

  ###############################################################################################
  # Client API

  def start_link(opts \\ []) do
    shipment_creation_interval = opts[:shipment_creation_interval] || 10_000

    opts =
      opts
      |> Keyword.merge(shipment_creation_interval: shipment_creation_interval, running_id: 0)
      |> Map.new()

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def set_interval(interval) do
    GenServer.call(__MODULE__, {:set_interval, interval})
  end

  ###############################################################################################
  # GenServer Callbacks

  def init(opts) do
    schedule_shipment_creation(opts)
    {:ok, opts}
  end

  def handle_info(:create_shipment, %{running_id: running_id} = opts) do
    next_id = running_id + 1

    event = %ShipmentRegistered{
      shipment_id: Integer.to_string(next_id),
      destination: Faker.Address.En.street_address()
    }

    :ok = Shared.EventPublisher.publish("shipment-#{next_id}", event, %{enacted_by: __MODULE__})
    Broadcaster.broadcast("OrderService", event)

    schedule_shipment_creation(opts)
    {:noreply, %{opts | running_id: next_id}}
  end

  def handle_call({:set_interval, interval}, _from, opts) do
    {:reply, :ok, Keyword.put(opts, :shipment_creation_interval, interval)}
  end

  ###############################################################################################
  # Private functions

  defp schedule_shipment_creation(opts) do
    Process.send_after(self(), :create_shipment, opts[:shipment_creation_interval])
  end
end
