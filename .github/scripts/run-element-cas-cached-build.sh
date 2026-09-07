#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

require_command cas-cache-server
require_command cas-cache-cli
require_project

CACHE_DIR="${ELEMENT_CACHE_DIR:-${ELEMENT_REPO_ROOT}/.ci/cas-build-cache}"
STATE_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/element-cas-build-cache/${ELEMENT_SCHEME}"
CONFIG_FILE="${STATE_DIR}/config.toml"
SOCKET_PATH="${HOME}/.local/state/element-cas-build-cache/cache.sock"
SERVER_LOG="${STATE_DIR}/server.log"
EXPORT_DIR="${STATE_DIR}/exports"

mkdir -p "$CACHE_DIR" "$STATE_DIR" "$EXPORT_DIR" "$(dirname "$SOCKET_PATH")"
rm -f "$SOCKET_PATH"

cat > "$CONFIG_FILE" <<EOF
[server]
socket_path = "${SOCKET_PATH}"
enable_write_to_disk = true
export_dir = "${EXPORT_DIR}"

[storage]
base_dir = "${CACHE_DIR}"
cas_backend = "file"
kv_backend = "sqlite"
cas_directory_levels = 2
verify_on_read = false
sqlite_wal_mode = true

[eviction]
max_size = "8 GB"
high_water_mark = 0.95
low_water_mark = 0.85
kv_ttl_seconds = 2592000
cas_ttl_seconds = 0
check_interval_seconds = 300
max_evict_per_cycle = 10000

[logging]
level = "debug"
format = "pretty"
EOF

RUST_LOG=cas_build_cache=debug cas-cache-server --config "$CONFIG_FILE" --foreground --verbose >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

stop_server() {
    if kill -0 "$SERVER_PID" 2>/dev/null; then
        kill -INT "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}
trap stop_server EXIT

for _ in $(seq 1 100); do
    [[ -S "$SOCKET_PATH" ]] && break
    kill -0 "$SERVER_PID" 2>/dev/null || {
        cat "$SERVER_LOG" >&2 || true
        exit 1
    }
    sleep 0.1
done

[[ -S "$SOCKET_PATH" ]] || {
    echo "CAS socket was not created: $SOCKET_PATH" >&2
    cat "$SERVER_LOG" >&2 || true
    exit 1
}

cas-cache-cli --config "$CONFIG_FILE" status
XCODE_XCCONFIG_FILE="${ELEMENT_REPO_ROOT}/.github/support/XcodeLocalCache.xcconfig" \
    "${SCRIPT_DIR}/run-element-build-for-testing.sh" "$@"

echo "Local CAS cache: $CACHE_DIR"
echo "Recent CAS requests:"
grep -E 'GetValue: (hit|miss)|Get: (hit|miss)|Put: success|Save: success' "$SERVER_LOG" | tail -n 100 || true
