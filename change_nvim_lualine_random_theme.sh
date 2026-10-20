#!/bin/bash

LUA_FILE="$HOME/Repos/dotfiles/nvim/init.lua"
THEME_DIR="$HOME/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes"

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      LUA_FILE="/mnt/d/Repos/dotfiles/nvim/init.lua"
      THEME_DIR="/home/ubuntu/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes"
    fi
    ;;
esac

THEMES=()
while IFS= read -r line; do
  THEMES+=("$line")
done < <(find "$THEME_DIR" -type f -name "*.lua" -exec basename {} .lua \; | sort)
THEME_CNT=${#THEMES[@]}

# 테마 목록이 비어있다면 종료
if ((THEME_CNT == 0)); then
  echo "❌ LuaLine Theme 목록을 불러올 수 없습니다."
  exit 1
fi

RANDOM_THEME="${THEMES[RANDOM % THEME_CNT]}"

echo "🔀 Change nvim lualine Random Theme 🎲"
echo "🎰 Theme Name : $RANDOM_THEME ♣️"

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|theme = \".*\"|theme = \"$RANDOM_THEME\"|" "$LUA_FILE"
    ;;
  *)
    sed -i "s|theme = \".*\"|theme = \"$RANDOM_THEME\"|" "$LUA_FILE"
    ;;
esac
