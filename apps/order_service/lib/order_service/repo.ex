defmodule OrderService.Repo do
  use Ecto.Repo,
    otp_app: :order_service,
    adapter: Ecto.Adapters.Postgres
end
