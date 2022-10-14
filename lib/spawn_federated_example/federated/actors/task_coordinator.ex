defmodule SpawnFederatedExample.Federated.Actors.TaskCoordinator do
  @moduledoc """
  `TaskCoordinator` Actor is the Actor responsible for dividing the work into sub-tasks
  and sending it to the workers.
  It must also take care of the aggregation logic.

  This logic is based on the Aggregator pattern
  https://www.enterpriseintegrationpatterns.com/patterns/messaging/Aggregator.html
  """
  use SpawnSdk.Actor,
    name: "task-coordinator",
    state_type: Federated.Domain.Coordinator.State,
    deactivate_timeout: 31_536_000_000

  require Logger

  alias Federated.Domain.{
    Data,
    FederatedTask,
    FederatedTaskResult,
    TaskRequest
  }

  alias Federated.Domain.Coordinator.{
    State,
    Worker,
    WorkerGroup
  }

  alias SpawnFederatedExample.Federated.Actors.Worker, as: ActorWorker

  defact push_task(
           %TaskRequest{
             id: task_id,
             workers: sub_tasks_number,
             data: %Data{numbers: arr} = _data
           } = request,
           %Context{state: state} = ctx
         ) do
    Logger.info(
      "TaskCoordinator Received Task for Processing. TaskRequest: [#{inspect(request)}] Context: [#{inspect(ctx)}]"
    )

    # Divide and conquer
    sub_list = split(arr, sub_tasks_number)

    # Create sub tasks containing the individual lists
    workers =
      sub_list
      |> Enum.with_index()
      |> Enum.map(fn {task_list, index} ->
        worker_id = "worker-#{inspect(index)}"

        task = %FederatedTask{
          id: Uniq.UUID.uuid4(),
          worker_id: worker_id,
          data: %Data{numbers: task_list},
          status: :PENDING
        }

        %Worker{id: worker_id, task: task}
      end)

    group = %WorkerGroup{id: task_id, workers: workers}

    # Prepare workers to compute work
    side_effects =
      group.workers
      |> Enum.map(fn worker ->
        worker_actor_name = worker.id
        # Start workers
        SpawnSdk.spawn_actor(worker_actor_name, system: "spawn-system", actor: ActorWorker)

        # Create a side effect for the worker
        SideEffect.to(worker_actor_name, :sum, worker.task)
      end)

    # Persist what happened so far and return the partial result.
    # Also send side effects for Workers to do the heavy lifting
    new_state =
      if is_nil(state) or state == %{} do
        %State{groups: [group]}
      else
        %State{state | groups: state.groups ++ [group]}
      end

    %Value{}
    |> Value.of(group, new_state)
    |> Value.effects(side_effects)
    |> Value.reply!()
  end

  defact aggregate_results(
           %FederatedTaskResult{} = worker_response,
           %Context{state: state} = _ctx
         ) do
    Logger.debug(
      "TaskCoordinator Received Aggregate Results to Join. Response: [#{inspect(worker_response)}]"
    )

    # TODO: Some crazy aggregation logic and save new state with aggregated result.

    %Value{}
    |> Value.state(state)
    |> Value.noreply!()
  end

  defp split(list, workers) do
    chunk_count = workers

    chunk_length = list |> Enum.count() |> div(chunk_count)

    list
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {e, i}, acc ->
      Map.update(acc, rem(div(i, chunk_length), chunk_count), [e], &[e | &1])
    end)
    |> Map.values()
    |> Enum.map(&Enum.reverse/1)
  end
end
