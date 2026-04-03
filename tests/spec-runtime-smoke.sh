#!/bin/sh
set -eu

ZMX_BIN=$1
TMPDIR_SPEC=$(mktemp -d)
export ZMX_DIR="$TMPDIR_SPEC"

cleanup() {
  "$ZMX_BIN" kill controller >/dev/null 2>&1 || true
  "$ZMX_BIN" kill task-test >/dev/null 2>&1 || true
  "$ZMX_BIN" kill long-output >/dev/null 2>&1 || true
  rm -rf "$TMPDIR_SPEC"
}

trap cleanup EXIT INT TERM

ready_json() {
  "$ZMX_BIN" create controller sh -lc 'printf ready\n; exec sleep 1' >/dev/null
  "$ZMX_BIN" wait controller --for ready --timeout 5s --json
}

task_json() {
  "$ZMX_BIN" run task-test sh -lc 'printf task-line\n; exit 0' >/dev/null
  "$ZMX_BIN" wait task-test --for task-exit --timeout 5s --json
}

long_output_json() {
  "$ZMX_BIN" run long-output sh -lc 'i=0; while [ "$i" -lt 200 ]; do printf "line-%s\n" "$i"; i=$((i+1)); done; exit 0' >/dev/null
  "$ZMX_BIN" wait long-output --for task-exit --timeout 5s >/dev/null
  "$ZMX_BIN" history long-output --json
}

READY_JSON=$(ready_json)
printf '%s' "$READY_JSON" | grep -F '"target":"ready"' >/dev/null
printf '%s' "$READY_JSON" | grep -F '"name":"controller"' >/dev/null

STATUS_OUTPUT=$("$ZMX_BIN" status controller)
printf '%s' "$STATUS_OUTPUT" | grep -F 'name=controller' >/dev/null

TASK_JSON=$(task_json)
printf '%s' "$TASK_JSON" | grep -F '"target":"task-exit"' >/dev/null
printf '%s' "$TASK_JSON" | grep -F '"name":"task-test"' >/dev/null
printf '%s' "$TASK_JSON" | grep -F '"task_exit_code":0' >/dev/null

LONG_OUTPUT_JSON=$(long_output_json)
printf '%s' "$LONG_OUTPUT_JSON" | grep -F '"encoding":"base64"' >/dev/null
printf '%s' "$LONG_OUTPUT_JSON" | grep -E '"byte_len":[1-9][0-9]+' >/dev/null

MISSING_JSON=$("$ZMX_BIN" wait missing --for ready --timeout 200ms --json || true)
printf '%s' "$MISSING_JSON" | grep -F '"requested_sessions":["missing"]' >/dev/null
