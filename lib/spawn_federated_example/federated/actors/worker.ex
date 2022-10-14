defmodule SpawnFederatedExample.Federated.Actors.Worker do
  @moduledoc """
  `Worker` does the heavy lifting and returns the results to the coordinator.
  """
  use SpawnSdk.Actor,
    abstract: true,
    persistent: false,
    channel: "workers",
    state_type: Google.Protobuf.Empty

  require Logger

  alias Federated.Domain.{
    Data,
    FederatedTask,
    FederatedTaskResult,
    Result
  }

  alias Google.Protobuf.Empty

  @coordinator_actor "task-coordinator"

  defact sum(
           %FederatedTask{id: id, worker_id: worker_id, data: %Data{numbers: list}} = request,
           %Context{state: state} = ctx
         ) do
    Logger.info(
      "Worker #{inspect(worker_id)} Received FederatedTask Request to Sum. Request: [#{inspect(request)}] Context: [#{inspect(ctx)}]"
    )

    sum = Enum.sum(list)

    result = %FederatedTaskResult{
      id: id,
      worker_id: worker_id,
      data: %Result{data: sum},
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
    |> Value.state(Empty.new())
    |> Value.noreply!()
  end
end
