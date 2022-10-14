# Spawn Federated Example

**TODO: Add description**

## Run

First up the Elixir application:

```shell
make run
``
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
iex(federated_01@127.0.0.1)6> SpawnFederatedExample.Client.push(task)

{:ok,
 %Federated.Domain.Coordinator.WorkerGroup{
   id: "15391a75-716d-4e2f-a9fa-3c9900d710b2",
   workers: [
     %Federated.Domain.Coordinator.Worker{
       id: "worker-0",
       task: %Federated.Domain.FederatedTask{
         id: "331131c9-14f2-4a73-9d56-bc24c42f28f2",
         worker_id: "worker-0",
         data: %Federated.Domain.Data{
           numbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
           __unknown_fields__: []
         },
         status: :PENDING,
         __unknown_fields__: []
       },
       __unknown_fields__: []
     },
     %Federated.Domain.Coordinator.Worker{
       id: "worker-1",
       task: %Federated.Domain.FederatedTask{
         id: "50bb96bb-886e-4656-b896-202dbaa2b279",
         worker_id: "worker-1",
         data: %Federated.Domain.Data{
           numbers: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
           __unknown_fields__: []
         },
         status: :PENDING,
         __unknown_fields__: []
       },
       __unknown_fields__: []
     }
   ],
   __unknown_fields__: []
 }}
```

In the logs you will see some messages like these:

```
2022-10-14 19:39:41.667 [federated_01@127.0.0.1]:[pid=<0.939.0> ]:[debug]:TaskCoordinator Received Aggregate Results to Join. Response: [%Federated.Domain.FederatedTaskResult{id: "331131c9-14f2-4a73-9d56-bc24c42f28f2", worker_id: "worker-0", data: %Federated.Domain.Result{data: 55, __unknown_fields__: []}, status: :DONE, __unknown_fields__: []}]

2022-10-14 19:39:41.669 [federated_01@127.0.0.1]:[pid=<0.939.0> ]:[debug]:TaskCoordinator Received Aggregate Results to Join. Response: [%Federated.Domain.FederatedTaskResult{id: "50bb96bb-886e-4656-b896-202dbaa2b279", worker_id: "worker-1", data: %Federated.Domain.Result{data: 155, __unknown_fields__: []}, status: :DONE, __unknown_fields__: []}]
```

This means that the Coordinator generated the subtasks, generated two workers worker-0 and worker-1 sent the subtasks to them and received the results back for aggregation.


## Checking the results

TODO