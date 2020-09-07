defmodule Shared.EventConsumer do
  defmacro __using__(opts) do
    quote do
      use GenServer
      require Logger

      # Adds default handle method
      @before_compile unquote(__MODULE__)

      @opts unquote(opts) || []

      def start_link(opts \\ []) do
        opts = Keyword.merge(@opts, opts)
        handler_module = @opts[:handler_module] || __MODULE__

        opts[:event_store] ||
          raise "EventConsumer: (event_store: MyApp.EventStore) configuration is missing"

        opts[:for_event] ||
          raise "EventConsumer: (for_event: MyApp.ExampleEvent) configuration is missing"

        opts = Keyword.merge(opts, handler_module: handler_module)

        GenServer.start_link(__MODULE__, opts, name: handler_module)
      end

      def received_events(subscriber) do
        GenServer.call(subscriber, :received_events)
      end

      def init(opts) do
        {:ok, subscription} =
          opts[:event_store].subscribe_to_all_streams("#{opts[:handler_module]}", self())

        state = opts |> Keyword.merge(subscription: subscription, events: []) |> Map.new()

        {:ok, state}
      end

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, state) do
        {:noreply, state}
      end

      # Event notification
      def handle_info({:events, events}, %{events: existing_events} = state) do
        for event <- events, do: handle_event(event, state)

        {:noreply, %{state | events: existing_events ++ events}}
      end

      def handle_call(:received_events, _from, %{events: events} = state) do
        {:reply, events, state}
      end

      def handle_event(event, %{handler_module: handler_module} = state) do
        case handler_module.handle(event) do
          :ok ->
            ack_event(event, state)

          error ->
            Logger.error(inspect(error))

            ack_event(event, state)
        end
      end

      def ack_event(event, %{event_store: event_store, subscription: subscription}) do
        :ok = event_store.ack(subscription, event)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      def handle(_event), do: :ok
      defoverridable handle: 1
    end
  end
end
