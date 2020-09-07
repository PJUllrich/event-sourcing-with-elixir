defmodule Shared.Application do
  use Application

  def start(_type, _args) do
    children =
      [
        {EventStore.Repo, []}
      ] ++ environment_specific_children(Mix.env())

    opts = [strategy: :one_for_one, name: Shared.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp environment_specific_children(:test), do: []
  defp environment_specific_children(_), do: [{Shared.EventStore, []}]
end
