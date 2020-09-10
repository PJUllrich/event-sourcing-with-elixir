defmodule Demo.OrderService do
  use GenServer

  alias Demo.Events.ShipmentRegistered

  ###############################################################################################
  # Client API

  def start_link(opts \\ []) do
    shipment_creation_interval = opts[:shipment_creation_interval] || 3_000

    opts = Keyword.merge(opts, shipment_creation_interval: shipment_creation_interval)

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

  def handle_info(:create_shipment, opts) do
    random_uuid = Faker.UUID.v4()
    event = %ShipmentRegistered{id: random_uuid, destination: Faker.Address.En.street_address()}
    :ok = Shared.EventPublisher.publish(random_uuid, event, %{enacted_by: __MODULE__})

    schedule_shipment_creation(opts)
    {:noreply, opts}
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
