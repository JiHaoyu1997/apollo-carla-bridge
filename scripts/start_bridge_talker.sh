#!/usr/bin/env bash
set -eo pipefail
if [[ $# -lt 1 || $# -gt 2 || ${1:-} == --help ]]; then
    echo "Usage: bash $0 <host-ipv4> [domain-id (default: 80)]"
    exit 0
fi
bridge_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
talker="$bridge_root/build/cyber/examples/cyber_example_talker"
if [[ ! -f "$bridge_root/build/setup.bash" || ! -x "$talker" ]]; then
    echo "Build first: cmake -S . -B build && cmake --build build --target cyber_example_talker" >&2
    exit 1
fi
source "$bridge_root/build/setup.bash"
# setup.bash provides defaults, so apply endpoint settings afterwards.
export CYBER_IP="$1"
export CYBER_DOMAIN_ID="${2:-80}"
echo 'Publishing channel/chatter (apollo.cyber.examples.proto.Chatter), 1 Hz' >&2
exec bash "$bridge_root/scripts/cyber_rtps.sh" "$talker"
