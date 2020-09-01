defmodule EventSourcingWithElixir.Repo do
  use Ecto.Repo,
    otp_app: :event_sourcing_with_elixir,
    adapter: Ecto.Adapters.Postgres
end
