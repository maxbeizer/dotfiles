#!/bin/bash
exec 2>/dev/null

INPUT=$(cat || true)
EVENT_TYPE="${COPILOT_HOOK_TYPE:-unknown}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/copilot-attention"

resolve_target_pane() {
  if [ -n "${TMUX_PANE:-}" ]; then
    printf '%s\n' "$TMUX_PANE"
    return 0
  fi

  tmux display-message -p '#{pane_id}' 2>/dev/null || true
}

session_name_for_pane() {
  local pane="$1"
  [ -n "$pane" ] || return 0

  tmux display-message -t "$pane" -p '#{session_name}' 2>/dev/null || true
}

pane_is_visible() {
  local pane="$1" client_pane
  [ -n "$pane" ] || return 1

  while IFS= read -r client_pane; do
    [ "$client_pane" = "$pane" ] && return 0
  done < <(tmux list-clients -F '#{client_pane}' 2>/dev/null)

  return 1
}

attention_marker() {
  local session="$1"
  [ -n "$session" ] || return 0

  local safe_session
  safe_session=$(printf '%s' "$session" | LC_ALL=C tr -c 'A-Za-z0-9._-' '_')
  printf '%s/%s\n' "$STATE_DIR" "$safe_session"
}

mark_attention() {
  local pane="$1" session marker
  session=$(session_name_for_pane "$pane")
  marker=$(attention_marker "$session")
  [ -n "$marker" ] || return 0

  mkdir -p "$STATE_DIR" || return 0
  printf '%s\n' "$session" > "$marker" || true
  [ -n "$pane" ] && tmux set-window-option -t "$pane" -q @copilot_attention 1 || true
}

# Send a terminal bell to the tmux pane so window_bell_flag lights up.
send_tmux_bell() {
  local target_pane="$1"
  [ -n "$target_pane" ] || return 1

  local pane_tty
  pane_tty=$(tmux display-message -t "$target_pane" -p '#{pane_tty}' 2>/dev/null) || return 1
  [ -n "$pane_tty" ] || return 1

  printf '\a' > "$pane_tty" 2>/dev/null
}

send_direct_bell() {
  [ -w /dev/tty ] || return 0
  printf '\a' > /dev/tty 2>/dev/null || true
}

notify_attention() {
  local pane
  pane=$(resolve_target_pane)
  if [ -z "$pane" ]; then
    send_direct_bell
    return 0
  fi

  if pane_is_visible "$pane"; then
    tmux set-window-option -t "$pane" -qu @copilot_attention || true
    return 0
  fi

  mark_attention "$pane"
  send_tmux_bell "$pane" || send_direct_bell
}

case "$EVENT_TYPE:$INPUT" in
  sessionEnd:*)
    notify_attention
    ;;
  agentStop:*)
    notify_attention
    ;;
  subagentStop:*)
    notify_attention
    ;;
  errorOccurred:*)
    notify_attention
    ;;
  *ask_user*)
    notify_attention
    ;;
esac
exit 0
