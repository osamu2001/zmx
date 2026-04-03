# Interactive Use

This guide is for humans driving `zmx` directly from a terminal.

## Pick the right command

- `zmx attach <name>` is the normal entry point when you want to jump into a session and interact with it immediately.
- `zmx create <name>` is useful when you want the session to exist first and attach later.
- `zmx run <name> ...` sends work into a session without attaching your terminal.
- `zmx detach` leaves the current session running and disconnects your client.
- `zmx status [name]` gives a short health-oriented summary.
- `zmx history <name>` lets you inspect scrollback without attaching.

## Common workflows

### Start a new interactive shell

```bash
zmx attach dev
```

This keeps the session alive after you detach or close the terminal window.

### Pre-create a session, then attach later

```bash
zmx create build
zmx attach build
```

This is useful when you want an explicit startup step before opening the UI.

### Send a command without attaching

```bash
zmx run tests go test ./...
zmx wait tests
```

Use `run` for task-shaped work. For a long-lived shell or editor session, prefer `create` or `attach`.

### Leave a session running

Detach with either:

- closing the terminal window
- pressing `ctrl+\`
- running `zmx detach`

After that, reconnect with:

```bash
zmx attach dev
```

### Check what is running

```bash
zmx status
zmx status dev
zmx list
zmx info dev --json
```

- `status` is the fast operator view.
- `list` shows every session.
- `info --json` is the detailed machine-readable probe.

### Read output after the fact

```bash
zmx history dev
zmx history dev --vt
zmx history dev --json
```

- plain output is good for humans
- `--vt` and `--html` preserve terminal escape output
- `--json` is intended for tooling and automation

## Human-first guidance

- Use `attach` when you want to work inside the session now.
- Use `create` when you want an explicit lifecycle step without opening a client.
- Use `run` when you want to enqueue work without attaching.

That split keeps the interactive path simple while still matching the runtime-oriented API described in `SPEC.md`.
