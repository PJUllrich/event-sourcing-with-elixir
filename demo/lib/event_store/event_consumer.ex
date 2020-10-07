defmodule Shared.EventConsumer do
  # A more complete version of this event_consumer macro can be found here:
  # https://github.com/PJUllrich/event-sourcing-with-elixir/blob/master/lib/event_store/event_consumer.ex

  defmacro __using__(opts) do
    quote do
      use GenServer
      require Logger

      # Adds default handle method
      @before_compile unquote(__MODULE__)

      def start_link(_opts) do
        handler_module = __MODULE__

        state = %{handler_module: handler_module}

        GenServer.start_link(handler_module, state, name: handler_module)
      end

      def init(opts), do: {:ok, subscribe(opts)}

      # Successfully subscribed to all streams
      def handle_info({:subscribed, subscription}, opts) do
        {:noreply, %{opts | subscription: subscription}}
      end

      # Event notification
      def handle_info({:events, events}, opts) do
        Enum.each(events, &handle_event(&1, opts))
        {:noreply, opts}
      end

      ###############################################################################################
      # Private functions

      defp subscribe(%{handler_module: handler_module} = opts) do
        {:ok, subscription} =
          Demo.EventStore.subscribe_to_all_streams("#{handler_module}", self())

        Map.merge(opts, %{subscription: subscription})
      end

      defp handle_event(
             %{data: event_data} = event,
             %{handler_module: handler_module} = opts
           ) do
        event_data
        |> handler_module.handle(event)
        |> case do
          :ok ->
            ack_event(opts, event)

          error ->
            Logger.error(inspect(error))
        end

        opts
      end

      defp ack_event(%{subscription: subscription} = opts, event) do
        :ok = Demo.EventStore.ack(subscription, event)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      def handle(_event_data), do: :ok

      defoverridable handle: 1

      def handle(event_data, _event), do: handle(event_data)

      defoverridable handle: 2
    end
  end
end
