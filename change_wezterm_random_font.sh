#!/bin/bash

WEZTERM_FILE="$HOME/Repos/dotfiles/.wezterm.lua"

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      WEZTERM_FILE="/mnt/c/Users/qkstj/.wezterm.lua"
    fi
    ;;
esac

FONT_LIST=$(fc-list : family | awk -F',' '$1 ~ /Nerd Font/ { print $1 }' | sed "s|\r||" | sort -u)

# 폰트 목록이 비어있다면 종료
if [[ -z "$FONT_LIST" ]]; then
  echo "❌ WezTerm Font 목록을 불러올 수 없습니다."
  exit 1
fi

IFS=$'\n' read -rd '' -a FONTS <<<"$FONT_LIST"

FONT_CNT=${#FONTS[@]}
RANDOM_FONT="${FONTS[RANDOM % FONT_CNT]}"

echo "🔀 Change Random FONT 🎲"
echo "🎰 FONT Name : $RANDOM_FONT ♣️ ($FONT_CNT fonts)"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|\".*Nerd Font|\"$RANDOM_FONT|" "$WEZTERM_FILE"
    ;;
  *)
    sed -i "s|\".*Nerd Font|\"$RANDOM_FONT|" "$WEZTERM_FILE"
    ;;
esac
