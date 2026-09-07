#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

clean_derived_data
echo "Removed Element DerivedData: ${ELEMENT_DERIVED_DATA_PATH}"
