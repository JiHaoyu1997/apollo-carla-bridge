#!/usr/bin/env bash
set -eo pipefail
bridge_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
exec docker build -f "$bridge_root/docker/Dockerfile" \
    -t "${BRIDGE_IMAGE:-apollo-carla-bridge:dev}" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE:-ubuntu:22.04}" \
    --build-arg "BUILD_JOBS=${BUILD_JOBS:-4}" \
    --build-arg "DEPENDENCY_PROXY=${DEPENDENCY_PROXY:-github}" \
    "$@" "$bridge_root"
