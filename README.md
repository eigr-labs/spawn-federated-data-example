# Spawn Federated Example

Certain use cases require more complex and careful modeling of Actors.
Here we exemplify the splitting and data aggregation scenario using Actors.

Targets:

Data Processing

Federated Machine Learning

Complex integration scenarios

## Run

First up the Elixir application:

```shell
make run
```

> **_NOTE:_** This example uses the MySQL database as persistent storage for its actors. And it is also expected that you have previously created a database called eigr-functions-db in the MySQL instance.

Second execute call for sending Task to Coordinator Actor:

```elixir
iex(federated_01@127.0.0.1)1>list = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
```

```elixir
iex(federated_01@127.0.0.1)4> task = %Federated.Domain.TaskRequest{
...(federated_01@127.0.0.1)4>      id: Uniq.UUID.uuid4(),
...(federated_01@127.0.0.1)4>      workers: 2,
...(federated_01@127.0.0.1)4>      data: %Federated.Domain.Data{numbers: list}
...(federated_01@127.0.0.1)4>    }

%Federated.Domain.TaskRequest{
  id: "15391a75-716d-4e2f-a9fa-3c9900d710b2",
  data: %Federated.Domain.Data{
    numbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
     20],
    __unknown_fields__: []
  },
  workers: 2,
  __unknown_fields__: []
}
```

```elixir
iex(federated_01@127.0.0.1)6> {:ok, task_id} = SpawnFederatedExample.Client.push(task)
{:ok, "86255146-8561-404a-b958-423d7c159ed2"}
```

In the logs you will see some messages like these:

```
2022-10-14 19:39:41.667 [federated_01@127.0.0.1]:[pid=<0.939.0> ]:[debug]:TaskCoordinator Received Aggregate Results to Join. Response: [%Federated.Domain.FederatedTaskResult{id: "331131c9-14f2-4a73-9d56-bc24c42f28f2", worker_id: "worker-0", data: %Federated.Domain.Result{data: 55, __unknown_fields__: []}, status: :DONE, __unknown_fields__: []}]

2022-10-14 19:39:41.669 [federated_01@127.0.0.1]:[pid=<0.939.0> ]:[debug]:TaskCoordinator Received Aggregate Results to Join. Response: [%Federated.Domain.FederatedTaskResult{id: "50bb96bb-886e-4656-b896-202dbaa2b279", worker_id: "worker-1", data: %Federated.Domain.Result{data: 155, __unknown_fields__: []}, status: :DONE, __unknown_fields__: []}]
```

This means that the Coordinator generated the subtasks, generated two workers worker-0 and worker-1 sent the subtasks to them and received the results back for aggregation.


## Checking the results

Use fetch operation for get aggregated task result:

```elixir
iex(federated_01@127.0.0.1)7>SpawnFederatedExample.Client.fetch(task_id)
{:ok,
 %Federated.Domain.Coordinator.Summary{
   task_id: "59cb2271-d88d-4a21-a240-d4a0b76f9020",
   sub_tasks: 2,
   response: %Federated.Domain.TaskResponse{
     id: "59cb2271-d88d-4a21-a240-d4a0b76f9020",
     result: %Federated.Domain.Result{data: 210, __unknown_fields__: []},
     __unknown_fields__: []
   },
   status: :DONE,
   __unknown_fields__: []
 }}
iex(federated_01@127.0.0.1)8>
```