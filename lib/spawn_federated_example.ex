defmodule SpawnFederatedExample do
  @moduledoc """
  Documentation for `SpawnFederatedExample`.
  """

  defmodule Client do
    alias SpawnSdk

    @coordinator_actor "task-coordinator"

    def push(task) do
      case SpawnSdk.invoke(
             @coordinator_actor,
             system: "spawn-system",
             command: "push_task",
             payload: task
           ) do
        {:ok, %Federated.Domain.Coordinator.WorkerGroup{id: id}} ->
          {:ok, id}

        _ ->
          :error
      end
    end
  end
end
