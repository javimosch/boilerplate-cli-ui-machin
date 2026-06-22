#!/usr/bin/env bash
# Build, then start the server in the foreground.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
exec ./boilerplate-cli-ui-machin start "$@"
