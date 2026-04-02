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
    \\  local commands="create attach run detach info input list completions kill history version help"
    \\
    \\  if [[ $COMP_CWORD -eq 1 ]]; then
    \\    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    \\    return 0
    \\  fi
    \\
    \\  case "$prev" in
    \\    create|attach|run|info|input|kill|history)
    \\      local sessions=$(zmx list --short 2>/dev/null | tr '\n' ' ')
    \\      COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
    \\      ;;
    \\    completions)
    \\      COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur"))
    \\      ;;
    \\    input)
    \\      COMPREPLY=($(compgen -W "--stdin --enter --no-newline" -- "$cur"))
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
    \\        'list:List active sessions'
    \\        'completions:Shell completion scripts'
    \\        'kill:Kill a session'
    \\        'history:Output session scrollback'
    \\        'version:Show version'
    \\        'help:Show help message'
    \\      )
    \\      _describe 'command' commands
    \\      ;;
    \\    args)
    \\      case $words[2] in
    \\        create|attach|a|kill|k|run|r|info|input|history|hi)
    \\          _zmx_sessions
    \\          ;;
    \\        completions|c)
    \\          _values 'shell' 'bash' 'zsh' 'fish'
    \\          ;;
    \\        input)
    \\          _values 'options' '--stdin' '--enter' '--no-newline'
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
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'l list' -d 'List active sessions'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'c completions' -d 'Shell completion scripts'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'k kill' -d 'Kill a session'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'hi history' -d 'Output session scrollback'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'v version' -d 'Show version'
    \\complete -c zmx -s v -l version -d 'Show version'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'w wait' -d 'Wait for session tasks to complete'
    \\complete -c zmx -n "__fish_is_nth_token 1" -a 'h help' -d 'Show help message'
    \\complete -c zmx -s h -d 'Show help message'
    \\
    \\complete -c zmx -n "__fish_is_nth_token 2; and __fish_seen_subcommand_from create a attach r run info input k kill hi history w wait" -a '(zmx list --short 2>/dev/null)' -d 'Session name'
    \\
    \\complete -c zmx -n "__fish_is_nth_token 2; and __fish_seen_subcommand_from c completions" -a 'bash zsh fish' -d Shell
    \\
    \\complete -c zmx -n "__fish_seen_subcommand_from input" -l stdin -d 'Read input from stdin'
    \\complete -c zmx -n "__fish_seen_subcommand_from input" -l enter -d 'Append carriage return'
    \\complete -c zmx -n "__fish_seen_subcommand_from input" -l no-newline -d 'Do not append a newline'
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

test "completion scripts include list json flag" {
    try std.testing.expect(std.mem.indexOf(u8, bash_completions, "--short --json") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh_completions, "'--json'") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish_completions, "-l json -d 'JSON output'") != null);
}
