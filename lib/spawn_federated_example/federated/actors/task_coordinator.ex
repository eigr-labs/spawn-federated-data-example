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
    state_type: Federated.Domain.Coordinator.State

  require Logger

  alias Federated.Domain.{
    Data,
    FederatedTask,
    FederatedTaskResult,
    Result,
    TaskRequest,
    TaskResponse
  }

  alias Federated.Domain.Coordinator.{
    Summary,
    State,
    Worker,
    WorkerGroup
  }

  alias SpawnFederatedExample.Federated.Actors.Worker, as: ActorWorker

  @doc """
  Divide the work to be done into several subtasks and
  send each subtask to a specific actor to process
  """
  defact push_task(
           %TaskRequest{
             id: task_id,
             workers: sub_tasks_number,
             data: %Data{numbers: arr} = _data
           } = request,
           %Context{state: state} = ctx
         ) do
    # Divide and conquer
    sub_list = split(arr, sub_tasks_number)

    # Create sub tasks containing the individual lists
    workers = build_workers(request, sub_list)

    group = %WorkerGroup{
      id: task_id,
      workers: workers,
      summary: %Summary{
        task_id: task_id,
        tasks: length(workers),
        response: %TaskResponse{id: task_id, result: %Result{}},
        status: :PENDING
      }
    }

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
        %State{groups: %{group.id => group}}
      else
        entry = Map.put(state.groups, group.id, group)
        %State{state | groups: entry}
      end

    %Value{}
    |> Value.of(group, new_state)
    |> Value.effects(side_effects)
    |> Value.reply!()
  end

  @doc """
  Aggregate results basead on some strategy
  """
  defact aggregate_results(worker_response, ctx) do
    Logger.debug("TaskCoordinator Received Aggregate Results to Join. Response:
      [#{inspect(worker_response)}]")

    # Some crazy aggregation logic and save new state with aggregated result.
    new_state = aggregate(worker_response, ctx)

    %Value{}
    |> Value.state(new_state)
    |> Value.noreply!()
  end

  defp aggregate(
         %FederatedTaskResult{
           id: task_id,
           correlation_id: correlation_id,
           worker_id: worker_id,
           status: status,
           data: %Result{} = result
         } = worker_response,
         %Context{state: %State{groups: groups} = state} = _ctx
       ) do
    worker_group =
      %WorkerGroup{
        id: worker_group_task_id,
        workers: workers,
        summary: summary
      } = Map.get(groups, correlation_id)

    new_workers_state =
      Enum.map(worker_group.workers, fn %Worker{task: task} = worker ->
        if worker.id == worker_id do
          updated_task = %FederatedTask{task | status: status}
          %Worker{worker | task: updated_task}
        else
          worker
        end
      end)

    pending_list =
      Enum.filter(new_workers_state, fn %Worker{task: %FederatedTask{status: status} = _task} =
                                          worker ->
        status == :PENDING
      end)

    summary_status = get_summary_status(pending_list)

    updated_worker_group = %WorkerGroup{
      worker_group
      | workers: new_workers_state,
        summary: %Summary{
          summary
          | status: summary_status,
            response: update_response(correlation_id, summary, summary_status, result)
        }
    }

    updated_groups = Map.replace(groups, correlation_id, updated_worker_group)

    new_state = %State{groups: updated_groups}
  end

  defp get_summary_status(list) do
    if length(list) > 0 do
      :PENDING
    else
      :DONE
    end
  end

  defp update_response(correlation_id, summary, summary_status, result) do
    case summary_status do
      :DONE ->
        res = %Result{
          summary.response.result
          | data: summary.response.result.data + result.data
        }

        %TaskResponse{summary.response | result: res}

      :PENDING ->
        %TaskResponse{summary.response | result: result}
    end
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

  defp build_workers(request, sub_list) do
    sub_list
    |> Enum.with_index()
    |> Enum.map(fn {task_list, index} ->
      worker_id = "worker-#{inspect(index)}-#{request.id}"

      task = %FederatedTask{
        id: Uniq.UUID.uuid4(),
        correlation_id: request.id,
        worker_id: worker_id,
        data: %Data{numbers: task_list},
        status: :PENDING
      }

      %Worker{id: worker_id, task: task}
    end)
  end
end
