defmodule Demo.Application do
  use Application

  def start(_type, _args) do
    children = [
      Demo.EventStore,
      Demo.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Demo.Application]
    Supervisor.start_link(children, opts)
  end
end
