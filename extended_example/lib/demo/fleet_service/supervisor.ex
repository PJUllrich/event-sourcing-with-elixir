defmodule FleetService.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, [args], name: __MODULE__)
  end

  def init([_args]) do
    children = [
      FleetService.ShipmentScheduledForDeliveryConsumer,
      FleetService
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
