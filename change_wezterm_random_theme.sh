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
  [[ -n "$line" ]] && THEMES+=("$line")
done < <(sed "s|\r||" "$SCHEMES_FILE")
THEME_CNT="${#THEMES[@]}"

# 테마 목록이 비어있다면 종료
if ((THEME_CNT == 0)); then
  echo "❌ WezTerm Scheme 목록을 불러올 수 없습니다."
  exit 1
fi

RANDOM_THEME="${THEMES[RANDOM % THEME_CNT]}"

echo "🔀 Change WezTerm Random Theme 🎲"
echo "🎰 Theme Name : $RANDOM_THEME ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|config.color_scheme = \".*\"|config.color_scheme = \"$RANDOM_THEME\"|" "$WEZTERM_FILE"
    ;;
  *)
    sed -i "s|config.color_scheme = \".*\"|config.color_scheme = \"$RANDOM_THEME\"|" "$WEZTERM_FILE"
    ;;
esac
