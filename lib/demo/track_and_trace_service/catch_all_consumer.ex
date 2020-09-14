defmodule TrackAndTraceService.CatchAllConsumer do
  use Shared.EventConsumer

  def handle(event, state) do
    TrackAndTraceService.Broadcaster.broadcast(event)
    {:ok, state}
  end
end
