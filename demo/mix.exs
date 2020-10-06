defmodule Demo.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_store_example,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Demo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventstore, "~> 1.1"},
      # Needed only if event data should be stored as JSON in Postgres
      {:jason, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      setup: ["event_store.create", "event_store.init"],
      test: ["event_store.init", "test"]
    ]
  end
end
