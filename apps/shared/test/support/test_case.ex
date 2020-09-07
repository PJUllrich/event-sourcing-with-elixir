defmodule Support.TestCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Arbeitszeitbestaetigung.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias EventStore.{Config}

  @event_store Shared.EventStore

  using do
    quote do
      import Support.ConcurrencyHelper
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EventStore.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EventStore.Repo, {:shared, self()})
    end

    {:ok, eventstore_connection} =
      @event_store
      |> Config.parsed(:shared)
      |> Config.default_postgrex_opts()
      |> Postgrex.start_link()

    EventStore.Storage.Initializer.reset!(eventstore_connection)
    {:ok, _} = Application.ensure_all_started(:eventstore)
    start_supervised!(@event_store)

    on_exit(fn ->
      Application.stop(:eventstore)
      Process.exit(eventstore_connection, :shutdown)
    end)

    :ok
  end
end
