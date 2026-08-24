#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0
ok=0
for t in test/host-test.reb test/host-stream-test.reb test/session-test.reb test/session-persist-test.reb test/session-fork-test.reb test/tools-test.reb \
         test/llm-test.reb test/llm-script-test.reb test/llm-stream-test.reb test/llm-http-stream-test.reb test/approval-test.reb test/shell-test.reb test/loop-test.reb \
         test/loop-cancel-test.reb test/isolate-test.reb test/scope-test.reb test/agent-test.reb test/yaml-boot-test.reb \
         test/full-chain-test.reb; do
  echo "######## $t ########"
  if r3 -s "$t"; then
    ok=$((ok + 1))
  else
    echo "FAIL $t"
    fail=$((fail + 1))
  fi
done
echo "-----"
echo "passed=$ok failed=$fail"
exit "$fail"
