defmodule AnalyticsService.CatchAllConsumer do
  use Shared.EventConsumer

  def handle(event, state) do
    Broadcaster.broadcast("AnalyticsService", event)
    {:ok, state}
  end
end
