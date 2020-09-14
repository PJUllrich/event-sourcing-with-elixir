defmodule TrackAndTraceService.Broadcaster do
  def broadcast(event) do
    Phoenix.PubSub.broadcast_from!(
      Demo.PubSub,
      self(),
      "TrackAndTraceService",
      event
    )
  end
end
