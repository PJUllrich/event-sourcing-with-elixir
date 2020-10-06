defmodule Shared.EventPublisher do
  alias EventStore.EventData

  require Logger

  def publish(stream_uuid, event, metadata) do
    Logger.info("Publishing: #{inspect(event)}")

    event_data = %EventData{
      event_type: to_string(event.__struct__),
      data: Map.from_struct(event),
      metadata: metadata
    }

    Shared.EventStore.append_to_stream(stream_uuid, :any_version, [event_data])
  end
end
