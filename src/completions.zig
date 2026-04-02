const std = @import("std");

pub const Shell = enum {
    bash,
    zsh,
    fish,

    pub fn fromString(s: []const u8) ?Shell {
        if (std.mem.eql(u8, s, "bash")) return .bash;
        if (std.mem.eql(u8, s, "zsh")) return .zsh;
        if (std.mem.eql(u8, s, "fish")) return .fish;

        return null;
    }

    pub fn getCompletionScript(self: Shell) []const u8 {
        return switch (self) {
            .bash => bash_completions,
            .zsh => zsh_completions,
            .fish => fish_completions,
        };
    }
};

const bash_completions =
    \\_zmx_completions() {
    \\  local cur prev words cword
    \\  COMPREPLY=()
    \\  cur="${COMP_WORDS[COMP_CWORD]}"
    \\  prev="${COMP_WORDS[COMP_CWORD-1]}"
    \\
    \\  local commands="create attach run detach info input send-keys set-meta get-meta remove-meta interrupt signal stop status list completions kill history wait version help"
    \\
    \\  if [[ $COMP_CWORD -eq 1 ]]; then
    \\    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    \\    return 0
    \\  fi
    \\
    \\  case "$prev" in
    \\    create|attach|run|info|input|send-keys|set-meta|get-meta|remove-meta|interrupt|signal|stop|status|kill|history|wait)
    \\      local sessions=$(zmx list --short 2>/dev/null | tr '\n' ' ')
    \\      COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
    \\      ;;
    \\    set-meta)
    \\      COMPREPLY=($(compgen -W "--json" -- "$cur"))
    \\      ;;
    \\    get-meta)
    \\      COMPREPLY=($(compgen -W "--json" -- "$cur"))
    \\      ;;
    \\    completions)
    \\      COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur"))
    \\      ;;
    \\    input)
    \\      COMPREPLY=($(compgen -W "--stdin --enter --no-newline" -- "$cur"))
    \\      ;;
    \\    send-keys)
    \\      COMPREPLY=($(compgen -W "enter escape ctrl-c up down left right tab backspace" -- "$cur"))
    \\      ;;
    \\    signal)
    \\      COMPREPLY=($(compgen -W "int term hup kill quit usr1 usr2 --foreground --session-tree --best-effort" -- "$cur"))
    \\      ;;
    \\    interrupt)
    \\      COMPREPLY=($(compgen -W "--best-effort" -- "$cur"))
    \\      ;;
    \\    stop)
    \\      COMPREPLY=($(compgen -W "--timeout-ms --escalate --best-effort" -- "$cur"))
    \\      ;;
    \\    wait)
    \\      COMPREPLY=($(compgen -W "--for --timeout ready task-exit session-exit" -- "$cur"))
    \\      ;;
    \\    list)
    \\      COMPREPLY=($(compgen -W "--short --json" -- "$cur"))
    \\      ;;
    \\    *)
    \\      ;;
    \\  esac
    \\}
    \\
    \\complete -o bashdefault -o default -F _zmx_completions zmx
;

const zsh_completions =
    \\_zmx() {
    \\  local context state state_descr line
    \\  typeset -A opt_args
    \\
    \\  _arguments -C \
    \\    '1: :->commands' \
    \\    '2: :->args' \
    \\    '*: :->trailing' \
    \\    && return 0
    \\
    \\  case $state in
    \\    commands)
    \\      local -a commands
    \\      commands=(
    \\        'create:Create a session without attaching'
    \\        'attach:Attach to session, creating if needed'
    \\        'run:Send command without attaching'
    \\        'detach:Detach all clients from current session'
    \\        'info:Show session details'
    \\        'input:Send text input without attaching'
    \\        'send-keys:Send special keys without attaching'
    \\        'set-meta:Store session metadata'
    \\        'get-meta:Read session metadata'
    \\        'remove-meta:Remove session metadata'
    \\        'interrupt:Send SIGINT to foreground process group'
    \\        'signal:Send a signal to foreground or session tree'
    \\        'stop:Gracefully stop a session'
    \\        'status:Show operator-oriented health summary'
    \\        'list:List active sessions'
    \\        'completions:Shell completion scripts'
    \\        'kill:Kill a session'
    \\        'history:Output session scrollback'
    \\        'wait:Wait for readiness or exit'
    \\        'version:Show version'
    \\        'help:Show help message'
    \\      )
    \\      _describe 'command' commands
    \\      ;;
    \\    args)
    \\      case $words[2] in
    \\        create|attach|a|kill|k|run|r|info|input|send-keys|set-meta|get-meta|remove-meta|interrupt|signal|stop|status|history|hi|wait|w)
    \\          _zmx_sessions
    \\          ;;
    \\        set-meta|get-meta)
    \\          _values 'options' '--json'
    \\          ;;
    \\        completions|c)
    \\          _values 'shell' 'bash' 'zsh' 'fish'
    \\          ;;
    \\        input)
    \\          _values 'options' '--stdin' '--enter' '--no-newline'
    \\          ;;
    \\        send-keys)
    \\          _values 'keys' 'enter' 'escape' 'ctrl-c' 'up' 'down' 'left' 'right' 'tab' 'backspace'
    \\          ;;
    \\        interrupt)
    \\          _values 'options' '--best-effort'
    \\          ;;
    \\        signal)
    \\          _values 'signals and options' 'int' 'term' 'hup' 'kill' 'quit' 'usr1' 'usr2' '--foreground' '--session-tree' '--best-effort'
    \\          ;;
    \\        stop)
    \\          _values 'options' '--timeout-ms' '--escalate' '--best-effort'
    \\          ;;
    \\        wait|w)
    \\          _values 'options' '--for' '--timeout' 'ready' 'task-exit' 'session-exit'
    \\          ;;
    \\        list|l)
    \\          _values 'options' '--short' '--json'
    \\          ;;
    \\      esac
    \\      ;;
    \\    trailing)
    \\      # Additional args for commands like 'attach' or 'run'
    \\      ;;
    \\  esac
    \\}
    \\
    \\_zmx_sessions() {
    \\  local -a sessions
    \\
    \\  local local_sessions=$(zmx list --short 2>/dev/null)
    \\  if [[ -n "$local_sessions" ]]; then
    \\    sessions+=(${(f)local_sessions})
    \\  fi
    \\
    \\  _describe 'local session' sessions
    \\}
    \\
    \\compdef _zmx zmx
;

const fish_completions =
    \\complete -c zmx -f
    \\
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'create' -d 'Create a session without attaching'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'a attach' -d 'Attach to session, creating if needed'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'r run' -d 'Send command without attaching'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'd detach' -d 'Detach all clients from current session'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'info' -d 'Show session details'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'input' -d 'Send text input without attaching'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'send-keys' -d 'Send special keys without attaching'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'set-meta' -d 'Store session metadata'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'get-meta' -d 'Read session metadata'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'remove-meta' -d 'Remove session metadata'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'interrupt' -d 'Send SIGINT to foreground process group'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'signal' -d 'Send a signal to foreground or session tree'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'stop' -d 'Gracefully stop a session'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'status' -d 'Show operator-oriented health summary'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'l list' -d 'List active sessions'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'c completions' -d 'Shell completion scripts'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'k kill' -d 'Kill a session'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'hi history' -d 'Output session scrollback'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'v version' -d 'Show version'
    \\complete -c zmx -s v -l version -d 'Show version'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'w wait' -d 'Wait for readiness or exit'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'h help' -d 'Show help message'
    \\complete -c zmx -s h -d 'Show help message'
    \\
    \\complete -c zmx -n "__fish_is_nth_token 2; and __fish_seen_subcommand_from create a attach r run info input send-keys set-meta get-meta remove-meta interrupt signal stop k kill hi history w wait" -a '(zmx list --short 2>/dev/null)' -d 'Session name'
    \\
    \\complete -c zmx -n "__fish_is_nth_token 2; and __fish_seen_subcommand_from c completions" -a 'bash zsh fish' -d Shell
    \\
    \\complete -c zmx -n "__fish_seen_subcommand_from input" -l stdin -d 'Read input from stdin'
    \\complete -c zmx -n "__fish_seen_subcommand_from input" -l enter -d 'Append carriage return'
    \\complete -c zmx -n "__fish_seen_subcommand_from input" -l no-newline -d 'Do not append a newline'
    \\complete -c zmx -n "__fish_seen_subcommand_from send-keys; and not __fish_is_nth_token 2" -a 'enter escape ctrl-c up down left right tab backspace' -d 'Special key'
    \\complete -c zmx -n "__fish_seen_subcommand_from set-meta get-meta" -l json -d 'JSON value/output'
    \\complete -c zmx -n "__fish_seen_subcommand_from interrupt" -l best-effort -d 'Ignore missing foreground process'
    \\complete -c zmx -n "__fish_seen_subcommand_from signal; and not __fish_is_nth_token 2" -a 'int term hup kill quit usr1 usr2' -d 'Signal name'
    \\complete -c zmx -n "__fish_seen_subcommand_from signal" -l foreground -d 'Target foreground process group'
    \\complete -c zmx -n "__fish_seen_subcommand_from signal" -l session-tree -d 'Target session process tree'
    \\complete -c zmx -n "__fish_seen_subcommand_from signal" -l best-effort -d 'Ignore missing target'
    \\complete -c zmx -n "__fish_seen_subcommand_from stop" -l timeout-ms -d 'Graceful shutdown timeout in milliseconds'
    \\complete -c zmx -n "__fish_seen_subcommand_from stop" -l escalate -d 'Escalate to SIGKILL after timeout'
    \\complete -c zmx -n "__fish_seen_subcommand_from stop" -l best-effort -d 'Ignore missing target'
    \\complete -c zmx -n "__fish_seen_subcommand_from w wait" -l for -d 'Wait target'
    \\complete -c zmx -n "__fish_seen_subcommand_from w wait" -l timeout -d 'Wait timeout (e.g. 500ms, 2s)'
    \\complete -c zmx -n "__fish_seen_subcommand_from w wait" -a 'ready task-exit session-exit' -d 'Wait target'
    \\complete -c zmx -n "__fish_seen_subcommand_from l list" -l short -d 'Short output'
    \\complete -c zmx -n "__fish_seen_subcommand_from l list" -l json -d 'JSON output'
    \\complete -c zmx -n "__fish_seen_subcommand_from hi history" -l vt -d 'History format for escape sequences'
    \\complete -c zmx -n "__fish_seen_subcommand_from hi history" -l html -d 'History format for escape sequences'
;

test "completion scripts include create command" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "create attach") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "create:Create a session without attaching") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'create' -d 'Create a session without attaching'") != null);
}

test "completion scripts include info command" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "info") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "info:Show session details") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'info' -d 'Show session details'") != null);
}

test "completion scripts include input command" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "input") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "input:Send text input without attaching") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'input' -d 'Send text input without attaching'") != null);
}

test "completion scripts include send-keys command" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "send-keys") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "send-keys:Send special keys without attaching") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'send-keys' -d 'Send special keys without attaching'") != null);
}

test "completion scripts include metadata commands" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "set-meta") != null);
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "get-meta") != null);
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "remove-meta") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "set-meta:Store session metadata") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "get-meta:Read session metadata") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'set-meta' -d 'Store session metadata'") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "-l json -d 'JSON value/output'") != null);
}

test "completion scripts include interrupt and signal commands" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "interrupt") != null);
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "signal") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "interrupt:Send SIGINT to foreground process group") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "signal:Send a signal to foreground or session tree") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'interrupt' -d 'Send SIGINT to foreground process group'") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'signal' -d 'Send a signal to foreground or session tree'") != null);
}

test "completion scripts include stop command" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "stop") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "stop:Gracefully stop a session") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'stop' -d 'Gracefully stop a session'") != null);
}

test "completion scripts include status command" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "status") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "status:Show operator-oriented health summary") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "a 'status' -d 'Show operator-oriented health summary'") != null);
}

test "completion scripts include list json flag" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "--short --json") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "'--json'") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "-l json -d 'JSON output'") != null);
}
