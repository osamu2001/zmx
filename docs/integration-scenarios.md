# Integration Scenarios

This document turns the Phase 4 runtime surface into concrete acceptance scenarios.

## Coverage map

| Scenario | Commands under test | Contract focus |
| --- | --- | --- |
| Gas City style controller flow | `create`, `set-meta`, `info --json`, `history --json`, `wait --for ready --json` | explicit lifecycle, metadata, readiness, non-lossy scrollback capture |
| Background task flow | `run`, `wait --for task-exit --json`, `history --json` | task completion, aggregate exit code, post-run history capture |
| Shell session flow | `create`, `attach`, `detach`, `status`, `info --json` | human attach path, runtime inspection, lifecycle separation |
| Long-output flow | `run`, `history --json`, `wait --json` | large scrollback retention, base64 history transport, stable final wait object |

## 1. Gas City style controller flow

Goal: a controller can start, inspect, and follow a session without using `attach`.

Suggested sequence:

```bash
zmx create mayor opencode
zmx set-meta mayor gc_alias mayor
zmx wait mayor --for ready --timeout 5s --json
zmx info mayor --json
zmx history mayor --json
```

Acceptance points:

- `create` returns successfully when the session already exists.
- `wait --for ready --json` returns a single structured result and no progress chatter.
- `info --json` exposes state, health, activity timestamps, task state, and metadata.
- `history --json` preserves the exact bytes of the captured scrollback through base64 transport.

## 2. Background task flow

Goal: task-shaped work can be launched and collected without attaching.

Suggested sequence:

```bash
zmx run tests go test ./...
zmx wait tests --for task-exit --json
zmx history tests --json
```

Acceptance points:

- `wait --for task-exit --json` reports the aggregate exit code.
- The final JSON payload reports the matched sessions explicitly without emitting progress chatter.
- Failed tasks still keep the same non-zero exit semantics as human mode.
- Scrollback remains available after the task exits.

## 3. Shell session flow

Goal: interactive users keep the current ergonomic path while gaining explicit inspection tools.

Suggested sequence:

```bash
zmx create dev
zmx attach dev
zmx detach
zmx status dev
zmx info dev --json
```

Acceptance points:

- `attach` remains human-first and can still create a missing session.
- `create` is available when a caller wants startup without side effects on the current terminal.
- `status` gives a concise operator summary.
- `info --json` gives the canonical machine-readable probe for the same session.

## 4. Long-output flow

Goal: large command output remains retrievable for automation.

Suggested sequence:

```bash
zmx run logs sh -lc 'yes line | head -n 5000'
zmx wait logs --for task-exit --json
zmx history logs --json
```

Acceptance points:

- `wait --json` remains a single final object even after long-running or verbose tasks.
- `history --json` can be decoded back to the original captured bytes.
- The scrollback contract is additive: human history output stays unchanged, while JSON is available when explicitly requested.
