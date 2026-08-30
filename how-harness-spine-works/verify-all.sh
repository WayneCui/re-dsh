#!/usr/bin/env bash
# Smoke: run each chapter lab. Labs are Rebol; CWD is always harness-spine
# because boot.reb loads ../cordis-port and sibling modules by relative path.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
fail=0
ok=0

if ! command -v r3 >/dev/null 2>&1; then
  echo "SKIP all chapters (r3 not on PATH)"
  echo "-----"
  echo "passed=0 failed=0"
  exit 0
fi

run_one() {
  local dir="$1"
  local rel="${dir#"$ROOT"/}"
  if (
    cd "$dir"
    bash run.sh >"$ROOT/.verify-out.txt" 2>"$ROOT/.verify-err.txt"
  ); then
    if grep -q "LAB-OK" "$ROOT/.verify-out.txt"; then
      echo "OK   $rel"
      ok=$((ok + 1))
    else
      echo "FAIL $rel (missing LAB-OK)"
      sed -n '1,30p' "$ROOT/.verify-out.txt" || true
      fail=$((fail + 1))
    fi
  else
    echo "FAIL $rel"
    sed -n '1,30p' "$ROOT/.verify-err.txt" || true
    sed -n '1,30p' "$ROOT/.verify-out.txt" || true
    fail=$((fail + 1))
  fi
}

for d in "$ROOT"/ch*/code; do
  [[ -d "$d" ]] || continue
  run_one "$d"
done

rm -f "$ROOT/.verify-out.txt" "$ROOT/.verify-err.txt"
echo "-----"
echo "passed=$ok failed=$fail"
exit "$fail"
