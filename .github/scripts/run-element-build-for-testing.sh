#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

require_command xcodebuild
require_project
require_xcode_config
print_test_configuration

xcodebuild \
    -project "$ELEMENT_PROJECT" \
    -scheme "$ELEMENT_SCHEME" \
    -configuration "$ELEMENT_CONFIGURATION" \
    -testPlan "$ELEMENT_TEST_PLAN" \
    -destination "$ELEMENT_DESTINATION" \
    -derivedDataPath "$ELEMENT_DERIVED_DATA_PATH" \
    -xcconfig "$XCODE_XCCONFIG_FILE" \
    -skipMacroValidation \
    build-for-testing \
    COMPILER_INDEX_STORE_ENABLE=NO \
    "$@"

echo "Generated XCTest run file:"
find_xctestrun
