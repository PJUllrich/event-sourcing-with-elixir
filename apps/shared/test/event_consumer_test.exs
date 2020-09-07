defmodule EventConsumerTest do
  use ExUnit.Case
  alias EventStore.EventData

  defmodule ExampleEvent do
    defstruct [:key]
  end

  test "subscribes to an event stream" do
    defmodule TestEventConsumer do
      use Shared.EventConsumer,
        event_store: Shared.EventStore,
        for_event: ExampleEvent
    end

    {:ok, subscriber} = TestEventConsumer.start_link()

    events = [
      %EventData{
        event_type: ExampleEvent |> to_string(),
        data: %{key: "test"},
        metadata: %{user: "someuser@example.com"}
      }
    ]

    :ok = Shared.EventStore.append("foo", events)
    :timer.sleep(100)

    assert [event] = TestEventConsumer.received_events(subscriber)
  end
end
