#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true:./lib/spawn_federated_example/federated/domain --proto_path=priv/protos/federated priv/protos/federated/federated.proto
protoc --elixir_out=gen_descriptors=true:./lib/spawn_federated_example/federated/domain --proto_path=priv/protos/federated priv/protos/federated/coordinator.proto
