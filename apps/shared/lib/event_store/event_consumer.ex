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

        opts =
          opts
          |> Keyword.merge(handler_module: handler_module, events: [])
          |> Map.new()

        GenServer.start_link(__MODULE__, opts, name: handler_module)
      end

      def received_events(subscriber) do
        GenServer.call(subscriber, :received_events)
      end

      def init(opts), do: {:ok, subscribe(opts)}

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, state) do
        {:noreply, state}
      end

      # Event notification
      def handle_info({:events, events}, state) do
        state = Enum.reduce(events, state, &handle_event/2)

        {:noreply, state}
      end

      def handle_call(:received_events, _from, %{events: events} = state) do
        {:reply, events, state}
      end

      defp handle_event(
             %{data: data} = event,
             %{handler_module: handler_module, events: events} = state
           ) do
        data
        |> handler_module.handle()
        |> case do
          :ok ->
            %{state | events: [event | events]}

          :not_handled ->
            state

          error ->
            Logger.error(inspect(error))
            state
        end
        |> ack_event(event)
      end

      defp ack_event(%{event_store: event_store, subscription: subscription} = state, event) do
        :ok = event_store.ack(subscription, event)
        state
      end

      defp subscribe(%{event_store: event_store, handler_module: handler_module} = state) do
        {:ok, subscription} = event_store.subscribe_to_all_streams("#{handler_module}", self())
        Map.merge(state, %{subscription: subscription})
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      def handle(_event), do: :not_handled

      defoverridable handle: 1
    end
  end
end
