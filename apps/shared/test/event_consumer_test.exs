defmodule EventConsumerTest do
  use Support.TestCase

  defmodule ExampleEvent do
    defstruct [:key]
  end

  defmodule AnotherExampleEvent do
    defstruct [:key]
  end

  test "subscribes to an event stream" do
    defmodule TestEventConsumer do
      use Shared.EventConsumer,
        event_store: Shared.EventStore

      def handle(%ExampleEvent{} = _event) do
        :ok
      end
    end

    {:ok, subscriber} = TestEventConsumer.start_link()

    event = %ExampleEvent{key: "test"}

    :ok = Shared.EventStore.append("foo", event, %{user: "someuser@example.com"})

    wait_until(fn ->
      assert [event] = TestEventConsumer.received_events(subscriber)
      assert event.event_type == ExampleEvent |> to_string()
      assert event.data == %ExampleEvent{key: "test"}
      assert event.event_id
      assert event.metadata == %{"user" => "someuser@example.com"}
      assert event.stream_uuid == "foo"
    end)
  end

  test "ignores events for which no handle/1 function was defined" do
    defmodule TestEventConsumer2 do
      use Shared.EventConsumer,
        event_store: Shared.EventStore

      def handle(%ExampleEvent{} = _event) do
        :ok
      end
    end

    {:ok, subscriber} = TestEventConsumer2.start_link()

    event = %ExampleEvent{key: "test"}
    not_handled_event = %AnotherExampleEvent{key: "test"}

    :ok = Shared.EventStore.append("foo", event, %{user: "someuser@example.com"})
    :ok = Shared.EventStore.append("foo", not_handled_event, %{user: "someuser@example.com"})

    wait_until(fn ->
      assert [event] = TestEventConsumer2.received_events(subscriber)
    end)
  end
end
