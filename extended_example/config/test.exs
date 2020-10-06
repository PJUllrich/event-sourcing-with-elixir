use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :demo, EventStore.Repo,
  username: "postgres",
  password: "postgres",
  database: "eventstore_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :demo, Shared.EventStore,
  column_data_type: "jsonb",
  serializer: EventStore.JsonbSerializer,
  types: EventStore.PostgresTypes,
  database: "eventstore_test#{System.get_env("MIX_TEST_PARTITION")}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :demo, Web.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
