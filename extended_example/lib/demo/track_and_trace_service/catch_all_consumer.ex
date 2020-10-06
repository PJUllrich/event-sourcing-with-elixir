defmodule TrackAndTraceService.CatchAllConsumer do
  use Shared.EventConsumer

  def handle(event, state) do
    Broadcaster.broadcast("TrackAndTraceService", event)
    {:ok, state}
  end
end
