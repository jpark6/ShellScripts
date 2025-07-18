#!/bin/bash

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      ALACRITTY_FILE="/mnt/d/Repos/dotfiles/alacritty/alacritty.toml"
      THEME_DIR="/mnt/d/Repos/dotfiles/alacritty/themes"
    ;;
  *)
    ALACRITTY_FILE="$HOME/Repos/dotfiles/alacritty/alacritty.toml"
    THEME_DIR="$HOME/Repos/dotfiles/alacritty/themes"
    ;;
esac

THEME_CNT=$(ls $THEME_DIR | wc -l)

THEMES=()
while IFS= read -r line; do
  THEMES+=("$line")
done < <(ls $THEME_DIR)

RANDOM_THEME="${THEMES[RANDOM % $THEME_CNT + 1]}"

echo "🔀 Change Alacritty Random Theme 🎲"
echo "🎰 Theme Name : $RANDOM_THEME ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|themes\/.*\"|themes\/$RANDOM_THEME\"|" $ALACRITTY_FILE
    ;;
  *)
    sed -i "s|themes\/.*\"|themes\/$RANDOM_THEME\"|" $ALACRITTY_FILE
    ;;
esac
