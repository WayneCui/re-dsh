#!/usr/bin/env bash
# Labs must run with CWD = harness-spine (boot.reb uses relative paths).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SPINE="$(cd "$HERE/../../.." && pwd)"
cd "$SPINE"
exec r3 -s "$HERE/demo.reb"
