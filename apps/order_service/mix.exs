defmodule OrderService.MixProject do
  use Mix.Project
  Code.require_file("../../config/shared.exs", __DIR__)

  def project do
    [
      app: :order_service,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OrderService.Application, []}
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
