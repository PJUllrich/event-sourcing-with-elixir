defmodule Shared.EventStore do
  use EventStore, otp_app: :shared

  alias EventStore.EventData

  def append(stream_uuid, event, metadata) do
    event_data = %EventData{
      event_type: to_string(event.__struct__),
      data: Map.from_struct(event),
      metadata: metadata
    }

    append_to_stream(stream_uuid, :any_version, [event_data])
  end
end
