defmodule SpawnFederatedExample do
  @moduledoc """
  Documentation for `SpawnFederatedExample`.
  """

  defmodule Client do
    alias SpawnSdk

    @coordinator_actor "task-coordinator"

    def push(task) do
      SpawnSdk.invoke(
        @coordinator_actor,
        system: "spawn-system",
        command: "push_task",
        payload: task
      )
    end
  end
end
