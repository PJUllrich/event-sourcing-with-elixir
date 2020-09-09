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

        opts[:event_store] ||
          raise "EventConsumer: (event_store: MyApp.EventStore) configuration is missing"

        opts =
          opts
          |> Keyword.merge(handler_module: handler_module, state: initial_state)
          |> Map.new()

        GenServer.start_link(handler_module, opts, name: handler_module)
      end

      def get_state(subscriber) do
        GenServer.call(subscriber, :get_state)
      end

      ###############################################################################################
      # GenServer Callbacks

      def init(opts), do: {:ok, subscribe(opts)}

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, opts) do
        {:noreply, opts}
      end

      # Event notification
      def handle_info({:events, events}, opts) do
        opts = Enum.reduce(events, opts, &handle_event/2)

        {:noreply, opts}
      end

      def handle_call(:get_state, _from, %{state: state} = opts) do
        {:reply, state, opts}
      end

      ###############################################################################################
      # Private functions

      defp subscribe(%{event_store: event_store, handler_module: handler_module} = opts) do
        {:ok, subscription} = event_store.subscribe_to_all_streams("#{handler_module}", self())
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
