#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

MODE="${ELEMENT_CACHE_MODE:-local}"
SKIP_SIMULATOR=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cache-mode) MODE="$2"; shift 2 ;;
        --skip-simulator) SKIP_SIMULATOR=true; shift ;;
        *) echo "Usage: $0 [--cache-mode local|remote] [--skip-simulator]" >&2; exit 2 ;;
    esac
done

case "$MODE" in
    local|remote) ;;
    *) echo "Cache mode must be local or remote" >&2; exit 2 ;;
esac

require_command xcodebuild
require_command xcrun
require_project
[[ -f "${ELEMENT_REPO_ROOT}/${ELEMENT_SCHEME}/SupportingFiles/${ELEMENT_TEST_PLAN}.xctestplan" ]] || {
    echo "Test plan not found: ${ELEMENT_SCHEME}.xctestplan" >&2
    exit 1
}

xcodebuild -version
xcodebuild -project "$ELEMENT_PROJECT" -scheme "$ELEMENT_SCHEME" -showBuildSettings >/dev/null

if [[ "$MODE" == local ]]; then
    require_command cas-cache-server
    require_command cas-cache-cli
else
    require_command xcodecacheprog
    [[ -f "${ELEMENT_REPO_ROOT}/.xcodecacheprog/project.json" ]] || {
        echo "Missing .xcodecacheprog/project.json" >&2
        exit 1
    }
    REMOTE_CONFIG="${ELEMENT_REMOTE_CONFIG:-${ELEMENT_REPO_ROOT}/XcodeRemoteCache.xcconfig}"
    if [[ ! -f "$REMOTE_CONFIG" && -f "${ELEMENT_REPO_ROOT}/.github/support/XcodeRemoteCache.xcconfig" ]]; then
        REMOTE_CONFIG="${ELEMENT_REPO_ROOT}/.github/support/XcodeRemoteCache.xcconfig"
    fi
    [[ -f "$REMOTE_CONFIG" ]] || {
        echo "Missing XcodeRemoteCache.xcconfig; run xcodecacheprog setup" >&2
        exit 1
    }
fi

if [[ "$SKIP_SIMULATOR" == false ]]; then
    xcrun simctl list devices available >/dev/null ||
        echo "Warning: CoreSimulator is unavailable; run again on a host with an iOS simulator" >&2
fi

echo "Xcode cache setup is ready for ${ELEMENT_SCHEME} (${MODE})"
