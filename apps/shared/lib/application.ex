defmodule Shared.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Shared.EventStore, []},
      {EventStore.Repo, []}
    ]

    opts = [strategy: :one_for_one, name: Shared.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
