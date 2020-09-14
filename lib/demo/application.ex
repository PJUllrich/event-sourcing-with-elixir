defmodule Demo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      environment_specific_children(Mix.env()) ++
        [
          EventStore.Repo,
          # Start the Telemetry supervisor
          Web.Telemetry,
          # Start the PubSub system
          {Phoenix.PubSub, name: Demo.PubSub},
          # Start the Endpoint (http/https)
          Web.Endpoint,
          {Demo.OrderService, []},
          {FulfillmentService.Supervisor, []},
          {TrackAndTraceService.Supervisor, []}
        ]

    Faker.start()

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end

  defp environment_specific_children(:test), do: []
  defp environment_specific_children(_), do: [{Shared.EventStore, []}]
end
