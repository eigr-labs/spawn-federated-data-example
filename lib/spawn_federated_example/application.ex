defmodule SpawnFederatedExample.Application do
  @moduledoc false

  use Application

  alias SpawnFederatedExample.Federated.Actors.{
    TaskCoordinator,
    Worker
  }

  @impl true
  def start(_type, _args) do
    children = [
      {
        SpawnSdk.System.Supervisor,
        system: "spawn-system",
        actors: [
          TaskCoordinator,
          Worker
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: SpawnFederatedExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
