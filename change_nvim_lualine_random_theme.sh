#!/bin/bash

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      LUA_FILE="/mnt/d/Repos/.settings/nvim/init.lua"
      THEME_DIR="/home/ubuntu/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes"
    else
      LUA_FILE="/home/jakepark/Repos/.settings/nvim/init.lua"
      THEME_DIR="/home/jakepark/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes"
    fi
    ;;
  Darwin*)
    LUA_FILE="/Users/jakepark/Repos/.settings/nvim/init.lua"
    THEME_DIR="/Users/jakepark/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes"
    ;;
  *)
    LUA_FILE="/home/jakepark/Repos/.settings/nvim/init.lua"
    THEME_DIR="/home/jakepark/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes"
    ;;
esac

THEME_CNT=$(ls $THEME_DIR | wc -l)

THEMES=()
while IFS= read -r line; do
  THEMES+=("$line")
done < <(ls $THEME_DIR)

RANDOM_THEME=$(echo "${THEMES[RANDOM % $THEME_CNT + 1]}" | sed 's|\.lua$||')

echo "🔀 Change nvim lualine Random Theme 🎲"
echo "🎰 Theme Name : $RANDOM_THEME ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|theme = \".*\"|theme = \"$RANDOM_THEME\"|" $LUA_FILE
    ;;
  *)
    sed -i "s|theme = \".*\"|theme = \"$RANDOM_THEME\"|" $LUA_FILE
    ;;
esac
