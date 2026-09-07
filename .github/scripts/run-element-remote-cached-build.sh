#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

require_command xcodecacheprog
require_project
[[ -n "${XCODECACHEPROG_TOKEN:-}" ]] || {
    echo "XCODECACHEPROG_TOKEN is required for remote cache builds" >&2
    exit 1
}

REMOTE_CONFIG="${ELEMENT_REMOTE_CONFIG:-${ELEMENT_REPO_ROOT}/XcodeRemoteCache.xcconfig}"
if [[ ! -f "$REMOTE_CONFIG" && -f "${ELEMENT_REPO_ROOT}/.github/support/XcodeRemoteCache.xcconfig" ]]; then
    REMOTE_CONFIG="${ELEMENT_REPO_ROOT}/.github/support/XcodeRemoteCache.xcconfig"
fi
[[ -f "$REMOTE_CONFIG" ]] || {
    echo "Remote cache config not found: $REMOTE_CONFIG" >&2
    exit 1
}
[[ -f "${ELEMENT_REPO_ROOT}/.xcodecacheprog/project.json" ]] || {
    echo "xcodecacheprog project metadata is missing" >&2
    exit 1
}

(
    cd "$ELEMENT_REPO_ROOT"
    xcodecacheprog sync \
        --credential-name "${XCODECACHEPROG_CREDENTIAL_NAME:-element-x-ios}" \
        --credential-env XCODECACHEPROG_TOKEN
    xcodecacheprog status
)

XCODE_XCCONFIG_FILE="$REMOTE_CONFIG" \
    "${SCRIPT_DIR}/run-element-build-for-testing.sh" "$@"
