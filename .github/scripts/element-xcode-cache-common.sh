#!/usr/bin/env bash

set -euo pipefail

ELEMENT_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ELEMENT_PROJECT="${ELEMENT_PROJECT:-${ELEMENT_REPO_ROOT}/ElementX.xcodeproj}"
ELEMENT_SCHEME="${ELEMENT_SCHEME:-UnitTests}"
ELEMENT_TEST_PLAN="${ELEMENT_TEST_PLAN:-${ELEMENT_SCHEME}}"
ELEMENT_CONFIGURATION="${ELEMENT_CONFIGURATION:-Debug}"
ELEMENT_DESTINATION="${ELEMENT_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5,arch=arm64}"
ELEMENT_DERIVED_DATA_PATH="${ELEMENT_DERIVED_DATA_PATH:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/element-xcodecache-derived-data/${ELEMENT_SCHEME}}"

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Required command is not installed: $1" >&2
        return 1
    }
}

require_project() {
    [[ -d "$ELEMENT_PROJECT" ]] || {
        echo "Xcode project not found: $ELEMENT_PROJECT" >&2
        return 1
    }
}

require_xcode_config() {
    [[ -n "${XCODE_XCCONFIG_FILE:-}" ]] || {
        echo "XCODE_XCCONFIG_FILE must point to an xcconfig file" >&2
        return 1
    }
    [[ -f "$XCODE_XCCONFIG_FILE" ]] || {
        echo "Xcode config not found: $XCODE_XCCONFIG_FILE" >&2
        return 1
    }
}

clean_derived_data() {
    rm -rf "$ELEMENT_DERIVED_DATA_PATH"
}

find_xctestrun() {
    local products_dir="${ELEMENT_DERIVED_DATA_PATH}/Build/Products"
    local xctestrun

    xctestrun="$(find "$products_dir" -type f -name "${ELEMENT_SCHEME}_${ELEMENT_TEST_PLAN}_*.xctestrun" -print -quit 2>/dev/null || true)"
    if [[ -z "$xctestrun" ]]; then
        echo "No ${ELEMENT_SCHEME}_${ELEMENT_TEST_PLAN}_*.xctestrun found under ${products_dir}" >&2
        find "$products_dir" -type f -name '*.xctestrun' -print >&2 2>/dev/null || true
        return 1
    fi

    cd "$(dirname "$xctestrun")"
    printf '%s/%s\n' "$(pwd)" "$(basename "$xctestrun")"
}

print_test_configuration() {
    echo "Project:       $ELEMENT_PROJECT"
    echo "Scheme:        $ELEMENT_SCHEME"
    echo "Test plan:     $ELEMENT_TEST_PLAN"
    echo "Configuration: $ELEMENT_CONFIGURATION"
    echo "Destination:   $ELEMENT_DESTINATION"
    echo "DerivedData:   $ELEMENT_DERIVED_DATA_PATH"
}
