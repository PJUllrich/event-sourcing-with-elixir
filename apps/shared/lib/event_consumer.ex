defmodule Shared.EventConsumer do
  defmacro __using__(opts) do
    quote do
      use GenServer

      @opts unquote(opts) || []

      def start_link(opts \\ []) do
        opts = Keyword.merge(@opts, opts)
        name = @opts[:name] || __MODULE__

        opts[:event_store] ||
          raise "EventConsumer: (event_store: MyApp.EventStore) configuration is missing"

        opts[:for_event] ||
          raise "EventConsumer: (for_event: MyApp.ExampleEvent) configuration is missing"

        opts = Keyword.merge(opts, name: name)

        GenServer.start_link(__MODULE__, opts, name: name)
      end

      def received_events(subscriber) do
        GenServer.call(subscriber, :received_events)
      end

      def init(opts) do
        {:ok, subscription} =
          opts[:event_store].subscribe_to_all_streams("#{opts[:name]}", self())

        state = opts |> Keyword.merge(subscription: subscription, events: []) |> Map.new()

        {:ok, state}
      end

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, state) do
        {:noreply, state}
      end

      # Event notification
      def handle_info({:events, events}, state) do
        %{event_store: event_store, events: existing_events, subscription: subscription} = state

        # Confirm receipt of received events
        :ok = event_store.ack(subscription, events)

        {:noreply, %{state | events: existing_events ++ events}}
      end

      def handle_call(:received_events, _from, %{events: events} = state) do
        {:reply, events, state}
      end
    end
  end
end
