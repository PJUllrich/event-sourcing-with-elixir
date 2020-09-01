# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :event_sourcing_with_elixir,
  ecto_repos: [EventSourcingWithElixir.Repo]

config :event_sourcing_with_elixir_web,
  ecto_repos: [EventSourcingWithElixir.Repo],
  generators: [context_app: :event_sourcing_with_elixir]

# Configures the endpoint
config :event_sourcing_with_elixir_web, EventSourcingWithElixirWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "EVpXubDe+9syCaSdOFHNIZwJqem1RaIX/pa5Xtd6+FkHJQ7L0O4rMTtR3hFy0xH/",
  render_errors: [view: EventSourcingWithElixirWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: EventSourcingWithElixir.PubSub,
  live_view: [signing_salt: "NGxug4VT"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
