defmodule EventSourcingWithElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      EventSourcingWithElixir.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: EventSourcingWithElixir.PubSub}
      # Start a worker by calling: EventSourcingWithElixir.Worker.start_link(arg)
      # {EventSourcingWithElixir.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EventSourcingWithElixir.Supervisor)
  end
end
