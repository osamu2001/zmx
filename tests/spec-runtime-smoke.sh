#!/bin/sh
set -eu

ZMX_BIN=$1
TMPDIR_SPEC=$(mktemp -d)
export ZMX_DIR="$TMPDIR_SPEC"

cleanup() {
  "$ZMX_BIN" kill controller >/dev/null 2>&1 || true
  "$ZMX_BIN" kill create-command >/dev/null 2>&1 || true
  "$ZMX_BIN" kill create-idempotent >/dev/null 2>&1 || true
  "$ZMX_BIN" kill create-login-shell >/dev/null 2>&1 || true
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

assert_fails_with_code() {
  expected_code=$1
  pattern=$2
  shift 2
  output_file=$(mktemp "$TMPDIR_SPEC/cmd-fail.XXXXXX")
  set +e
  "$ZMX_BIN" "$@" > "$output_file" 2>&1
  status=$?
  set -e
  output=$(cat "$output_file")
  rm -f "$output_file"
  if [ "$status" -ne "$expected_code" ]; then
    printf '%s\n' "expected exit code ${expected_code}, got ${status}: ${*}" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
  assert_contains "$output" "$pattern"
}

extract_json_number() {
  printf '%s' "$1" | tr -d '\n' | grep -o "\"$2\":[0-9]*" | head -n 1 | cut -d: -f2
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

CREATE_STDOUT=$(mktemp "$TMPDIR_SPEC/create-stdout.XXXXXX")
"$ZMX_BIN" create create-command sh -lc 'while :; do sleep 1; done' > "$CREATE_STDOUT"
assert_contains "$(cat "$CREATE_STDOUT")" 'session "create-command" created'
CREATE_INFO_JSON=$("$ZMX_BIN" info create-command --json)
assert_contains "$CREATE_INFO_JSON" '"name":"create-command"'
assert_contains "$CREATE_INFO_JSON" '"pid":'

CREATE_PID1=$(extract_json_number "$CREATE_INFO_JSON" pid)
"$ZMX_BIN" create create-command sh -lc 'echo should-not-start-second-time'
CREATE_INFO_JSON2=$("$ZMX_BIN" info create-command --json)
CREATE_PID2=$(extract_json_number "$CREATE_INFO_JSON2" pid)
if [ "$CREATE_PID1" != "$CREATE_PID2" ]; then
  printf '%s\n' "create idempotency check failed: pid changed" >&2
  exit 1
fi

CREATE_LOGIN_STDOUT=$(mktemp "$TMPDIR_SPEC/create-login-stdout.XXXXXX")
"$ZMX_BIN" create create-login-shell > "$CREATE_LOGIN_STDOUT"
CREATE_LOGIN_JSON=$("$ZMX_BIN" info create-login-shell --json)
assert_contains "$CREATE_LOGIN_JSON" '"name":"create-login-shell"'
assert_contains "$CREATE_LOGIN_JSON" '"cmd":null'

assert_contains "$CREATE_LOGIN_JSON" '"state":"idle"'
assert_contains "$CREATE_LOGIN_JSON" '"healthy":true'
assert_contains "$CREATE_LOGIN_JSON" '"pid":'
assert_contains "$CREATE_LOGIN_JSON" '"clients":'
assert_contains "$CREATE_LOGIN_JSON" '"cmd":null'
assert_contains "$CREATE_LOGIN_JSON" '"cwd":'
assert_contains "$CREATE_LOGIN_JSON" '"task":'
assert_contains "$CREATE_LOGIN_JSON" '"meta":'

STATUS_OUTPUT=$("$ZMX_BIN" status controller)
assert_contains "$STATUS_OUTPUT" 'name=controller'

INFO_MISSING_JSON=$("$ZMX_BIN" info missing --json 2>/dev/null || true)
assert_contains "$INFO_MISSING_JSON" '"error":{'
assert_contains "$INFO_MISSING_JSON" '"code":"session_not_found"'
assert_contains "$INFO_MISSING_JSON" "\"message\":\"session 'missing' not found\""

INFO_MISSING_TEXT=$("$ZMX_BIN" info missing 2>&1 || true)
assert_contains "$INFO_MISSING_TEXT" 'error: session "missing" does not exist'

TASK_JSON=$(task_json)
assert_contains "$TASK_JSON" '"target":"task-exit"'
assert_contains "$TASK_JSON" '"name":"task-test"'
assert_contains "$TASK_JSON" '"task_exit_code":0'

LONG_OUTPUT_JSON=$(long_output_json)
assert_contains "$LONG_OUTPUT_JSON" '"encoding":"base64"'
printf '%s' "$LONG_OUTPUT_JSON" | grep -E '"byte_len":[1-9][0-9]+' >/dev/null

MISSING_JSON=$("$ZMX_BIN" wait missing --for ready --timeout 200ms --json || true)
assert_contains "$MISSING_JSON" '"requested_sessions":["missing"]'

assert_fails_with_code 3 "error: session \"missing\" does not exist" kill missing
assert_fails_with_code 6 "error: unsupported signal \"banana\"" signal missing banana
