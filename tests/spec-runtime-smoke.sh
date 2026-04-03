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

assert_contains() {
  value=$1
  needle=$2
  printf '%s' "$value" | grep -F "$needle" >/dev/null
}

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
assert_contains "$READY_JSON" '"target":"ready"'
assert_contains "$READY_JSON" '"name":"controller"'

STATUS_OUTPUT=$("$ZMX_BIN" status controller)
assert_contains "$STATUS_OUTPUT" 'name=controller'

TASK_JSON=$(task_json)
assert_contains "$TASK_JSON" '"target":"task-exit"'
assert_contains "$TASK_JSON" '"name":"task-test"'
assert_contains "$TASK_JSON" '"task_exit_code":0'

LONG_OUTPUT_JSON=$(long_output_json)
assert_contains "$LONG_OUTPUT_JSON" '"encoding":"base64"'
printf '%s' "$LONG_OUTPUT_JSON" | grep -E '"byte_len":[1-9][0-9]+' >/dev/null

MISSING_JSON=$("$ZMX_BIN" wait missing --for ready --timeout 200ms --json || true)
assert_contains "$MISSING_JSON" '"requested_sessions":["missing"]'
