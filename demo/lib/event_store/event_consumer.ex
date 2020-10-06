defmodule Shared.EventConsumer do
  # A more complete version of this event_consumer macro can be found here:
  # https://github.com/PJUllrich/event-sourcing-with-elixir/blob/master/lib/event_store/event_consumer.ex

  defmacro __using__(opts) do
    quote do
      use GenServer
      require Logger

      # Adds default handle method
      @before_compile unquote(__MODULE__)

      def start_link(opts) do
        handler_module = opts[:handler_module] || __MODULE__
        initial_state = opts[:initial_state] || %{}
        event_store = opts[:event_store] || Demo.EventStore

        opts =
          opts
          |> Keyword.merge(
            handler_module: handler_module,
            state: initial_state,
            event_store: event_store
          )
          |> Map.new()

        GenServer.start_link(handler_module, opts, name: handler_module)
      end

      def init(opts), do: {:ok, subscribe(opts)}

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, opts) do
        {:noreply, %{opts | subscription: subscription}}
      end

      # Event notification
      def handle_info({:events, events}, opts) do
        opts = Enum.reduce(events, opts, &handle_event/2)

        {:noreply, opts}
      end

      ###############################################################################################
      # Private functions

      defp subscribe(%{handler_module: handler_module, event_store: event_store} = opts) do
        {:ok, subscription} =
          event_store.subscribe_to_all_streams(
            subscription_name(opts),
            self()
          )

        Map.merge(opts, %{subscription: subscription})
      end

      defp subscription_name(%{handler_module: handler_module} = _opts) do
        "#{handler_module}"
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
