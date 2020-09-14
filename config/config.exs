# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :demo,
  ecto_repos: [EventStore.Repo],
  event_stores: [Shared.EventStore]

# Configures the endpoint
config :demo, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "N4HX2rebF2fWFq0BcjMQKxAFMrDhTcW4evDHp1oTsW6Cz42O0iuVq0l6c52r8q+l",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Demo.PubSub,
  live_view: [signing_salt: "Ew3EZ6mO"]

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  slimleex: PhoenixSlime.LiveViewEngine

# Configures Elixir's Logger
config :logger, :console,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
