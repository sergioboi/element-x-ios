#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/element-xcode-cache-common.sh"

rm -rf "${ELEMENT_CACHE_DIR:-${ELEMENT_REPO_ROOT}/.ci/cas-build-cache}"
echo "Removed local Element Xcode cache directory"
