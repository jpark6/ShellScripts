#!/bin/bash

WEZTERM_FILE="$HOME/Repos/dotfiles/.wezterm.lua"
SCHEMES_FILE="$HOME/Repos/dotfiles/wezterm_color_scheme_list.txt"

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      WEZTERM_FILE="/mnt/c/Users/qkstj/.wezterm.lua"
      SCHEMES_FILE="/mnt/d/Repos/dotfiles/wezterm_color_scheme_list.txt"
    fi
    ;;
esac

THEMES=()
while IFS= read -r line; do
  THEMES+=("$line")
done < <(cat $SCHEMES_FILE)
THEME_CNT="${#THEMES[@]}"

RANDOM_THEME="$(echo "${THEMES[RANDOM % $THEME_CNT ]}" | sed "s|\r||")"

echo "🔀 Change WezTerm Random Theme 🎲"
echo "🎰 Theme Name : $RANDOM_THEME ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|config.color_scheme = \".*\"|config.color_scheme = \"$RANDOM_THEME\"|" $WEZTERM_FILE
    ;;
  *)
    sed -i "s|config.color_scheme = \".*\"|config.color_scheme = \"$RANDOM_THEME\"|" $WEZTERM_FILE
    ;;
esac
