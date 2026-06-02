#!/bin/bash
INPUT=$(cat)
EVENT_TYPE="${COPILOT_HOOK_TYPE:-unknown}"

# Send a terminal bell to the tmux pane so window_bell_flag lights up.
send_tmux_bell() {
  [ -n "${TMUX_PANE:-}" ] || return 0

  local pane_tty
  pane_tty=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_tty}' 2>/dev/null) || return 0
  if [ -n "$pane_tty" ]; then
    printf '\a' > "$pane_tty" 2>/dev/null || true
  fi
}

case "$EVENT_TYPE" in
  sessionEnd)
    send_tmux_bell
    ;;
  preToolUse)
    # Notify when the agent is waiting for user input. Keep this parser simple
    # and fail-open so the safety hook never blocks Copilot tool calls.
    if printf '%s' "$INPUT" | grep -Eq '"toolName"[[:space:]]*:[[:space:]]*"ask_user"|"tool_name"[[:space:]]*:[[:space:]]*"ask_user"'; then
      send_tmux_bell
    fi
    ;;
  postToolUse)
    # kept for backward compat; primary ask_user detection is in preToolUse
    ;;
esac
exit 0
