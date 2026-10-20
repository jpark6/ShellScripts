#!/bin/bash

ALACRITTY_FILE="$HOME/Repos/dotfiles/alacritty/alacritty.toml"
THEME_DIR="$HOME/Repos/dotfiles/alacritty/themes"

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      ALACRITTY_FILE="/mnt/d/Repos/dotfiles/alacritty/alacritty.toml"
      THEME_DIR="/mnt/d/Repos/dotfiles/alacritty/themes"
    fi
    ;;
esac

THEMES=()
while IFS= read -r line; do
  THEMES+=("$line")
done < <(find "$THEME_DIR" -type f -name "*.toml" -exec basename {} \; | sort)
THEME_CNT=${#THEMES[@]}

# 테마 목록이 비어있다면 종료
if ((THEME_CNT == 0)); then
  echo "❌ Alacritty Theme 목록을 불러올 수 없습니다."
  exit 1
fi

RANDOM_THEME="${THEMES[RANDOM % THEME_CNT]}"

echo "🔀 Change Alacritty Random Theme 🎲"
echo "🎰 Theme Name : $RANDOM_THEME ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|themes\/.*\"|themes\/$RANDOM_THEME\"|" "$ALACRITTY_FILE"
    ;;
  *)
    sed -i "s|themes\/.*\"|themes\/$RANDOM_THEME\"|" "$ALACRITTY_FILE"
    ;;
esac
