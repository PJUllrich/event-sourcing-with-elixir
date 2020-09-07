defmodule Shared.EventStore do
  use EventStore, otp_app: :shared

  def append(stream_uuid, events) do
    append_to_stream(stream_uuid, :any_version, events)
  end
end
