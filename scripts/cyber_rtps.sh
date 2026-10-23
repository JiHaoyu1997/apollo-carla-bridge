#!/usr/bin/env bash
# Run a Cyber command with a private RTPS-only cross-process configuration.
set -eo pipefail
if [[ $# -eq 0 || ${1:-} == --help ]]; then
    echo "Usage: CYBER_IP=<reachable-ip> CYBER_DOMAIN_ID=<domain> $0 <command> [args...]"
    echo "Source the local Cyber setup before invoking this script."
    exit 0
fi
: "${CYBER_PATH:?Source the Cyber environment first}"
: "${CYBER_IP:?Set CYBER_IP to a reachable IPv4 address}"
: "${CYBER_DOMAIN_ID:?Set CYBER_DOMAIN_ID identically on both endpoints}"
if [[ ! -f "$CYBER_PATH/conf/cyber.pb.conf" ]]; then
    echo "Missing configuration: $CYBER_PATH/conf/cyber.pb.conf" >&2
    exit 1
fi
runtime_dir=$(mktemp -d /tmp/bridge-cyber-XXXXXX)
child_pid=
cleanup() {
    if [[ -n $child_pid ]] && kill -0 "$child_pid" 2>/dev/null; then
        kill -TERM "$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
    fi
    rm -rf -- "$runtime_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cp -R "$CYBER_PATH/conf" "$runtime_dir/conf"
# GlobalData reads conf/cyber.pb.conf under CYBER_PATH. Preserve other settings.
# Replace active entries only; commented examples remain untouched.
sed -E \
    -e 's/^([[:space:]]*diff_proc:)[[:space:]]*[A-Z_]+/\1 RTPS/' \
    -e 's/^([[:space:]]*diff_host:)[[:space:]]*[A-Z_]+/\1 RTPS/' \
    "$runtime_dir/conf/cyber.pb.conf" > "$runtime_dir/conf/cyber.pb.conf.new"
mv "$runtime_dir/conf/cyber.pb.conf.new" "$runtime_dir/conf/cyber.pb.conf"
if ! grep -Eq '^[[:space:]]*diff_proc:[[:space:]]*RTPS' "$runtime_dir/conf/cyber.pb.conf"; then
    echo "No active diff_proc setting found; cannot ensure RTPS transport." >&2
    exit 1
fi
export CYBER_PATH="$runtime_dir"
echo "Cyber RTPS: IP=$CYBER_IP DOMAIN=$CYBER_DOMAIN_ID command=$*" >&2
"$@" &
child_pid=$!
set +e
wait "$child_pid"
result=$?
set -e
child_pid=
exit "$result"
