defmodule Shared.MixProject do
  use Mix.Project
  Code.require_file("../../config/shared.exs", __DIR__)

  def project do
    [
      app: :shared,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Shared.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    SharedConfig.deps() ++ []
  end

  defp aliases do
    SharedConfig.aliases() ++ []
  end
end
