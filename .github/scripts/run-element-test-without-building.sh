#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

require_command xcodebuild
require_project
XCTESTRUN_PATH="$(find_xctestrun)"
RESULT_BUNDLE_PATH="${ELEMENT_RESULT_BUNDLE_PATH:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/element-${ELEMENT_SCHEME}-xcodebuild.xcresult}"
rm -rf "$RESULT_BUNDLE_PATH"

echo "Running xcodebuild test-without-building"
echo "XCTest run:    $XCTESTRUN_PATH"
echo "Result bundle: $RESULT_BUNDLE_PATH"

xcodebuild \
    test-without-building \
    -xctestrun "$XCTESTRUN_PATH" \
    -destination "$ELEMENT_DESTINATION" \
    -resultBundlePath "$RESULT_BUNDLE_PATH" \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 60 \
    -maximum-test-execution-time-allowance 60 \
    "$@"
