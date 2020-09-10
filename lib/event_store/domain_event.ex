defmodule Shared.DomainEvent do
  defmacro __using__(_opts) do
    quote do
      defimpl String.Chars, for: __MODULE__ do
        def to_string(event) do
          event |> Map.from_struct() |> Map.to_list() |> List.to_string()
        end
      end
    end
  end
end
