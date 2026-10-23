#!/usr/bin/env bash
set -eo pipefail
cd /opt/bridge
source /opt/bridge/docker/environment.bash
if [[ ${1:-} == talker ]]; then
    shift
    exec ./build/cyber/examples/cyber_example_talker "$@"
fi
if [[ $# -eq 0 ]]; then
    exec bash
fi
exec "$@"
