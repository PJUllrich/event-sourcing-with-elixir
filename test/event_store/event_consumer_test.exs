defmodule EventStore.EventConsumerTest do
  use Support.TestCase

  defmodule ExampleEvent do
    defstruct [:key]
  end

  defmodule AnotherExampleEvent do
    defstruct [:key]
  end

  defmodule TestEventConsumer do
    use Shared.EventConsumer,
      event_store: Shared.EventStore,
      initial_state: %{events: []}

    def handle(%ExampleEvent{} = _event_data, %{events: events} = state, event) do
      {:ok, %{state | events: [event | events]}}
    end
  end

  describe "EventConsumer" do
    test "subscribes to an event stream" do
      {:ok, subscriber} = TestEventConsumer.start_link()

      event = %ExampleEvent{key: "test"}

      :ok = Shared.EventPublisher.publish("foo", event, %{user: "someuser@example.com"})

      wait_until(fn ->
        assert %{events: [event]} = TestEventConsumer.get_state(subscriber)
        assert event.event_type == ExampleEvent |> to_string()
        assert event.data == %ExampleEvent{key: "test"}
        assert event.event_id
        assert event.metadata == %{"user" => "someuser@example.com"}
        assert event.stream_uuid == "foo"
      end)
    end

    test "ignores events for which no handle/3 function was defined" do
      {:ok, subscriber} = TestEventConsumer.start_link()

      event = %ExampleEvent{key: "test"}
      not_handled_event = %AnotherExampleEvent{key: "test"}

      :ok = Shared.EventPublisher.publish("foo1", event, %{user: "someuser@example.com"})

      :ok =
        Shared.EventPublisher.publish("foo1", not_handled_event, %{user: "someuser@example.com"})

      wait_until(fn ->
        assert %{events: [event]} = TestEventConsumer.get_state(subscriber)
      end)
    end

    test "can be paused" do
      {:ok, subscriber} = TestEventConsumer.start_link()
      event = %ExampleEvent{key: "first event"}
      :ok = Shared.EventPublisher.publish("foo2", event, %{user: "someuser@example.com"})

      wait_until(fn ->
        assert %{events: [event]} = TestEventConsumer.get_state(subscriber)
      end)

      :ok = TestEventConsumer.pause(subscriber)

      event = %ExampleEvent{key: "first event"}
      :ok = Shared.EventPublisher.publish("foo2", event, %{user: "someuser@example.com"})

      wait_until(fn ->
        assert %{events: [event]} = TestEventConsumer.get_state(subscriber)
      end)

      :ok = TestEventConsumer.resume(subscriber)

      wait_until(fn ->
        assert %{events: [second_event, first_event]} = TestEventConsumer.get_state(subscriber)
      end)
    end
  end
end
