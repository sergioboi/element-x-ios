#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${ELEMENT_CACHE_MODE:-local}" in
    local) exec "${SCRIPT_DIR}/run-element-cas-cached-build.sh" "$@" ;;
    remote) exec "${SCRIPT_DIR}/run-element-remote-cached-build.sh" "$@" ;;
    *) echo "ELEMENT_CACHE_MODE must be local or remote" >&2; exit 1 ;;
esac
