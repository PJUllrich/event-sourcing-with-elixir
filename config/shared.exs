defmodule SharedConfig do
  def deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:eventstore, "~> 1.1"},
      {:jason, "~> 1.1"}
    ]
  end

  def aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "event_store.init"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "event_store.init", "test"]
    ]
  end
end
