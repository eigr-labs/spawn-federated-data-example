defmodule SpawnFederatedExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :spawn_federated_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SpawnFederatedExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn_sdk, "~> 0.1.0"},
      {:spawn_statestores, "~> 0.1.0"},
      {:uniq, "~> 0.5.3"}
    ]
  end
end
