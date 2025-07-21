#!/bin/bash

WEZTERM_FILE="$HOME/Repos/dotfiles/.wezterm.lua"

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      WEZTERM_FILE="/mnt/c/Users/qkstj/.wezterm.lua"
    fi
    ;;
esac

FONT_LIST=$(fc-list : family | awk -F',' ' $1~/Nerd Font/ { print $1 } ' | sort | uniq )

IFS=$'\n' read -rd '' -a FONTS <<<"$FONT_LIST"

FONT_CNT=${#FONTS[@]}
RANDOM_FONT="${FONTS[RANDOM % $FONT_CNT + 1]}"
echo $RANDOM_FONT

echo $FONT_CNT
echo "🔀 Change Random FONT 🎲"
echo "🎰 FONT Name : $RANDOM_FONT ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|wezterm.font(\".*\",|wezterm.font(\"$RANDOM_FONT\",|" $WEZTERM_FILE
    ;;
  *)
    sed -i "s|wezterm.font(\".*\",|wezterm.font(\"$RANDOM_FONT\",|" $WEZTERM_FILE
    ;;
esac
