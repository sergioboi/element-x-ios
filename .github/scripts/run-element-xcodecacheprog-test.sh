#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

require_command xcodecacheprog
XCTESTRUN_PATH="$(find_xctestrun)"
ARGS=(test --xctestrun "$XCTESTRUN_PATH" --destination "$ELEMENT_DESTINATION")

if [[ "${ELEMENT_CACHE_MODE:-remote}" == "local" ]]; then
    ARGS+=(--local-cache-storage)
else
    [[ -n "${XCODECACHEPROG_TOKEN:-}" ]] || {
        echo "XCODECACHEPROG_TOKEN is required for remote xcodecacheprog tests" >&2
        exit 1
    }
    [[ -f "${ELEMENT_REPO_ROOT}/.xcodecacheprog/project.json" ]] || {
        echo "xcodecacheprog project metadata is missing" >&2
        exit 1
    }
fi

echo "Running xcodecacheprog test"
echo "XCTest run: $XCTESTRUN_PATH"
(
    cd "$ELEMENT_REPO_ROOT"
    if [[ "${ELEMENT_CACHE_MODE:-remote}" != "local" ]]; then
        xcodecacheprog sync \
            --credential-name "${XCODECACHEPROG_CREDENTIAL_NAME:-element-x-ios}" \
            --credential-env XCODECACHEPROG_TOKEN
    fi
    xcodecacheprog "${ARGS[@]}" "$@"
)
