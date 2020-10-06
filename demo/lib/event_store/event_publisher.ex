defmodule Shared.EventPublisher do
  alias EventStore.EventData

  require Logger

  def publish(stream_uuid, event, metadata, version \\ :any_version) do
    event_data = %EventData{
      event_type: to_string(event.__struct__),
      data: Map.from_struct(event),
      metadata: metadata
    }

    Demo.EventStore.append_to_stream(stream_uuid, version, [event_data])
  end
end
