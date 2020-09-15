defmodule Broadcaster do
  def broadcast(topic, event) do
    Phoenix.PubSub.broadcast_from!(
      Demo.PubSub,
      self(),
      topic,
      event
    )
  end
end
