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
        state =
          for event <- events, reduce: state do
            state -> handle_event(event, state)
          end

        {:noreply, state}
      end

      def handle_call(:received_events, _from, %{events: events} = state) do
        {:reply, events, state}
      end

      defp handle_event(
             %{data: data} = event,
             %{handler_module: handler_module, events: events} = state
           ) do
        ack_event(event, state)

        case handler_module.handle(data) do
          :ok ->
            %{state | events: [event | events]}

          :not_handled ->
            state

          error ->
            Logger.error(inspect(error))
            state
        end
      end

      defp ack_event(event, %{event_store: event_store, subscription: subscription}) do
        :ok = event_store.ack(subscription, event)
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
