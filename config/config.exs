# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :shared,
  ecto_repos: [EventStore.Repo],
  event_stores: [Shared.EventStore]

config :order_service, ecto_repos: [OrderService.Repo]

config :shared, EventStore.Repo,
  database: "eventstore_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :order_service, OrderService.Repo,
  database: "order_service_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :shared, Shared.EventStore,
  column_data_type: "jsonb",
  serializer: EventStore.JsonbSerializer,
  types: EventStore.PostgresTypes,
  database: "eventstore_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

import_config "#{Mix.env()}.exs"
