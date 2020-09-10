defmodule FulfillmentService.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    children = [
      FulfillmentService.ShipmentRegisteredConsumer,
      FulfillmentService
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
