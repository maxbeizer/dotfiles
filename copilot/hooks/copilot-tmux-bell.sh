#!/bin/bash
exec 2>/dev/null

INPUT=$(cat || true)
EVENT_TYPE="${COPILOT_HOOK_TYPE:-unknown}"

# Send a terminal bell to the tmux pane so window_bell_flag lights up.
send_tmux_bell() {
  local target_pane="${TMUX_PANE:-}"
  if [ -z "$target_pane" ]; then
    target_pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null) || return 0
  fi

  local pane_tty
  pane_tty=$(tmux display-message -t "$target_pane" -p '#{pane_tty}' 2>/dev/null) || return 0
  if [ -n "$pane_tty" ]; then
    printf '\a' > "$pane_tty" 2>/dev/null || true
  fi
}

case "$EVENT_TYPE" in
  sessionEnd)
    send_tmux_bell
    ;;
  preToolUse)
    # Notify when the agent is waiting for user input. Use bash-only matching
    # and fail-open so the safety hook never blocks Copilot tool calls.
    if [[ "$INPUT" == *ask_user* ]]; then
      send_tmux_bell
    fi
    ;;
  postToolUse)
    # kept for backward compat; primary ask_user detection is in preToolUse
    ;;
esac
exit 0
