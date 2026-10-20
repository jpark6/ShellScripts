#!/bin/bash

# attach 되지 않은 tmux 세션 이름 목록 (세션 이름에 ':' 이 있어도 안전하도록 -F 사용)
TMUX_SESSION_LIST=$(tmux ls -F '#{session_attached}|#{session_name}' 2>/dev/null | awk -F'|' '$1 == 0 { print substr($0, index($0, "|") + 1) }')

while IFS= read -r SESSION; do
  if [[ -n "$SESSION" ]]; then
    tmux kill-session -t "$SESSION"
  fi
done <<<"$TMUX_SESSION_LIST"
