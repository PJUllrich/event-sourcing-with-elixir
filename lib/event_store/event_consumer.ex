defmodule Shared.EventConsumer do
  defmacro __using__(opts) do
    quote do
      use GenServer
      require Logger

      # Adds default handle method
      @before_compile unquote(__MODULE__)

      @opts unquote(opts) || []

      ###############################################################################################
      # Client API

      def start_link(opts \\ []) do
        opts = Keyword.merge(@opts, opts)
        handler_module = @opts[:handler_module] || __MODULE__
        initial_state = @opts[:initial_state] || %{}
        start_from = @opts[:start_from] || :origin

        opts[:event_store] ||
          raise "EventConsumer: (event_store: MyApp.EventStore) configuration is missing"

        opts =
          opts
          |> Keyword.merge(
            handler_module: handler_module,
            start_from: start_from,
            state: initial_state
          )
          |> Map.new()

        GenServer.start_link(handler_module, opts, name: handler_module)
      end

      def get_state(subscriber), do: GenServer.call(subscriber, :get_state)

      def pause(subscriber), do: GenServer.call(subscriber, :pause)

      def resume(subscriber), do: GenServer.call(subscriber, :subscribe)

      ###############################################################################################
      # GenServer Callbacks

      def init(opts), do: {:ok, subscribe(opts)}

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, opts) do
        {:noreply, %{opts | subscription: subscription}}
      end

      # Event notification
      def handle_info({:events, events}, opts) do
        opts = Enum.reduce(events, opts, &handle_event/2)
        opts = inc_event_counter(opts, events)

        {:noreply, opts}
      end

      def handle_call(:subscribe, _from, opts) do
        {:reply, :ok, subscribe(opts)}
      end

      def handle_call(:get_state, _from, %{state: state} = opts) do
        {:reply, state, opts}
      end

      def handle_call(
            :pause,
            _from,
            %{event_store: event_store, subscription: subscription} = opts
          ) do
        :ok = event_store.unsubscribe_from_all_streams(subscription_name(opts))
        {:reply, :ok, opts}
      end

      ###############################################################################################
      # Private functions

      defp subscribe(
             %{event_store: event_store, handler_module: handler_module, start_from: start_from} =
               opts
           ) do
        {:ok, subscription} =
          event_store.subscribe_to_all_streams(
            subscription_name(opts),
            self(),
            start_from: start_from
          )

        Map.merge(opts, %{subscription: subscription})
      end

      defp handle_event(
             %{data: event_data} = event,
             %{handler_module: handler_module, state: old_state} = opts
           ) do
        new_state =
          event_data
          |> handler_module.handle(old_state, event)
          |> case do
            {:ok, new_state} ->
              # Only acknowledge the event
              ack_event(opts, event)
              new_state

            error ->
              Logger.error(inspect(error))
              old_state
          end

        %{opts | state: new_state}
      end

      defp ack_event(%{event_store: event_store, subscription: subscription} = opts, event) do
        :ok = event_store.ack(subscription, event)
      end

      defp subscription_name(%{handler_module: handler_module} = _opts) do
        "#{handler_module}"
      end

      def inc_event_counter(%{start_from: :origin} = opts, events),
        do: %{opts | start_from: length(events)}

      def inc_event_counter(%{start_from: start_form} = opts, events) do
        start_form = start_form + length(events)
        %{opts | start_from: start_form}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      def handle(_event_data, state), do: {:ok, state}

      defoverridable handle: 2

      def handle(event_data, state, _event), do: handle(event_data, state)

      defoverridable handle: 3
    end
  end
end
