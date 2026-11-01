#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --editor --import --quit > /tmp/echo-import.log 2>&1
if rg 'SCRIPT ERROR|Parse Error|Compile Error' /tmp/echo-import.log; then exit 1; fi
for suite in tests/run_tests.gd tests/ui_smoke.gd; do
  log=$(mktemp)
  godot --headless --path . --script "$suite" > "$log" 2>&1 || { cat "$log"; rm "$log"; exit 1; }
  cat "$log"
  if rg 'SCRIPT ERROR|ERROR:' "$log"; then rm "$log"; exit 1; fi
  rm "$log"
done
