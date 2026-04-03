# Automation and Controllers

`zmx` can now be treated as an explicit runtime backend instead of only an interactive terminal helper.

## Recommended flow

For controllers and local automation, prefer this sequence:

1. `zmx create <name> [command...]`
2. `zmx set-meta <name> <key> <value>`
3. `zmx info <name> --json`
4. `zmx input`, `zmx send-keys`, `zmx signal`, `zmx interrupt`, or `zmx stop`
5. `zmx wait <name>... --for ... --json`
6. `zmx history <name> --json` when you need scrollback capture

This keeps lifecycle, control, and inspection separate.

## Command roles

- `create` is the idempotent startup primitive. It makes the session exist without attaching a client.
- `attach` is for humans. It remains intentionally user-friendly and may create the session as a convenience.
- `run` is task-shaped. Use it when you want to enqueue work without attaching, not as a generic runtime bootstrap.

## JSON contracts

The preferred machine-readable commands are:

- `zmx info <name> --json`
- `zmx list --json`
- `zmx get-meta <name> [key] --json`
- `zmx history <name> --json`
- `zmx wait <name>... --json`

Rules:

- JSON is opt-in.
- Timestamps are RFC3339 UTC.
- Missing values are `null`.
- JSON-mode errors use `{"error":{"code":"...","message":"..."}}`.

## History capture

`history --json` returns the raw scrollback bytes as base64:

```json
{
  "name": "mayor",
  "format": "plain",
  "encoding": "base64",
  "content_b64": "bG9nIGxpbmUgMQo=",
  "byte_len": 11
}
```

This keeps the JSON contract additive and non-lossy even for VT output.

## Wait semantics

`wait --json` emits one final structured object on success and no progress chatter:

- `--for ready` completes when the matching sessions are probeable with a live child process.
- `--for task-exit` completes when the matching task sessions have finished and preserves aggregate exit semantics.
- `--for session-exit` completes when the matched sessions disappear after first being observed.

Successful payloads include:

- target
- aggregate exit code when applicable
- matched session count
- one `sessions[]` entry per matched session with name, completion state, health, and task exit code

Errors keep the same exit-code contract as human mode:

- timeout: exit 5
- no matching sessions: exit 2
- sessions disappeared before completion: exit 1

JSON-mode errors also include the wait target and the requested session names so a controller can attribute the failure.

## Export status

`export` is deferred on purpose.

Reasoning:

- the current automation surface is already usable with `info --json`, `history --json`, `wait --json`, and metadata
- implementing export/import too early would add format and persistence questions before the existing runtime contract settles
- keeping it as optional backlog avoids making Phase 4 a blocker for controller adoption
