use Mix.Config

config :event_store_example,
  event_stores: [Demo.EventStore]

config :event_store_example, Demo.EventStore,
  column_data_type: "jsonb",
  serializer: EventStore.JsonbSerializer,
  types: EventStore.PostgresTypes,
  username: "postgres",
  password: "postgres",
  database: "eventstore_example",
  hostname: "localhost"

config :logger, :console, level: :info
