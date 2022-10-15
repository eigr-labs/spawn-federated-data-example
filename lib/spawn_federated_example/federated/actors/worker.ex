defmodule SpawnFederatedExample.Federated.Actors.Worker do
  @moduledoc """
  `Worker` does the heavy lifting and returns the results to the coordinator.
  """
  use SpawnSdk.Actor,
    abstract: true,
    persistent: false,
    channel: "workers"

  require Logger

  alias Federated.Domain.{
    Data,
    FederatedTask,
    FederatedTaskResult,
    Result
  }

  @coordinator_actor "task-coordinator"

  defact sum(
           %FederatedTask{
             id: id,
             correlation_id: correlation_id,
             worker_id: worker_id,
             data: %Data{} = data,
             task_strategy: task_strategy
           } = request,
           %Context{} = ctx
         ) do
    Logger.info(
      "Worker #{inspect(worker_id)} Received FederatedTask Request to Sum. Request: [#{inspect(request)}] Context: [#{inspect(ctx)}]"
    )

    value = calculate(data, task_strategy)

    result = %FederatedTaskResult{
      id: id,
      correlation_id: correlation_id,
      worker_id: worker_id,
      data: %Result{data: value},
      status: :DONE
    }

    # Send result to Coordinator Actor for aggregate results
    invoke(
      @coordinator_actor,
      system: "spawn-system",
      command: "aggregate_results",
      payload: result,
      async: true
    )

    Value.of()
    |> Value.noreply!(force: true)
  end

  defp calculate(%Data{numbers: list} = _data, task_strategy) do
    case task_strategy do
      :SUM ->
        Enum.sum(list)

      :MIN ->
        Enum.min(list)

      :MAX ->
        Enum.max(list)

      :UNKNOWN_TASK_STRATEGY ->
        Enum.sum(list)
    end
  end
end
