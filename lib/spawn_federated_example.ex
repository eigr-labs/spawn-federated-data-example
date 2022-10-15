defmodule SpawnFederatedExample do
  @moduledoc """
  Documentation for `SpawnFederatedExample`.
  """

  defmodule Client do
    alias SpawnSdk

    alias Federated.Domain.Coordinator.{
      GetTaskRequest,
      GetTaskResponse,
      WorkerGroup
    }

    @coordinator_actor "task-coordinator"

    def push(task) do
      case SpawnSdk.invoke(
             @coordinator_actor,
             system: "spawn-system",
             command: "push_task",
             payload: task
           ) do
        {:ok, %WorkerGroup{id: id}} ->
          {:ok, id}

        _ ->
          :error
      end
    end

    def fetch(task_id) do
      request = %GetTaskRequest{id: task_id}

      case SpawnSdk.invoke(
             @coordinator_actor,
             system: "spawn-system",
             command: "fetch",
             payload: request
           ) do
        {:ok, %GetTaskResponse{summary: summary}} ->
          {:ok, summary}

        _ ->
          :error
      end
    end
  end
end
