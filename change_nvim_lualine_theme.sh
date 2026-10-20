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

# 테마 Lua를 nvim 으로 직접 실행해 모드별 a/b/c 섹션의 "모드 섹션 fg bg" 목록 출력
# (require 로 다른 테마를 가져오거나 vim.opt 를 읽는 테마도 해석됨)
dump_theme() {
  local rtp
  rtp="$(dirname "$(dirname "$(dirname "$THEME_DIR")")")" # .../lualine.nvim
  LL_THEME="$1" LL_RTP="$rtp" nvim --headless -u NONE -l /dev/stdin 2>/dev/null <<'EOF'
local name = vim.env.LL_THEME
vim.opt.runtimepath:append(vim.env.LL_RTP)
local ok, t = pcall(require, "lualine.themes." .. name)
if not ok or type(t) ~= "table" then return end
for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
  local m = t[mode]
  if m then
    for _, sec in ipairs({ "a", "b", "c" }) do
      local s = m[sec]
      if s and s.fg and s.bg then
        io.stdout:write(string.format("%s %s %s %s\n", mode, sec, s.fg, s.bg))
      end
    end
  end
end
EOF
}

# 테마 미리보기: preview_theme <테마 이름>
preview_theme() {
  local name="$1" data mode sec fg bg last=""
  printf '\033[1m%s\033[0m\n\n' "$name"

  data=$(dump_theme "$name")
  if [[ -z "$data" ]]; then
    echo "(색상을 불러올 수 없습니다 — 외부 파일에 의존하는 테마)"
    return 0
  fi

  # 16진수 → "R;G;B"
  rgb() {
    local h="${1#\#}"
    printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
  }

  # 모드별 한 줄: a / b / c 섹션을 상태줄처럼 이어서 표시
  while read -r mode sec fg bg; do
    if [[ "$mode" != "$last" ]]; then
      [[ -n "$last" ]] && printf '\033[0m\n'
      printf '%-8s ' "$mode"
      last="$mode"
    fi
    printf '\033[38;2;%s;48;2;%sm %s \033[0m' "$(rgb "$fg")" "$(rgb "$bg")" "$(echo "$mode" | tr '[:lower:]' '[:upper:]' | cut -c1-3)$sec"
  done <<<"$data"
  printf '\033[0m\n'

  case "$name" in
    auto) printf '\n(auto: 현재 컬러스킴에서 계산되므로 실제 색은 다를 수 있음)\n' ;;
  esac
}

# fzf --preview 에서 재호출되는 미리보기 모드: $0 --preview <테마 이름>
if [[ "$1" == "--preview" ]]; then
  preview_theme "$2"
  exit 0
fi

# 현재 사용 가능한 theme 목록 가져오기
THEMES=$(find "$THEME_DIR" -type f -name "*.lua" -exec basename {} .lua \; | sort)

# 프리셋 목록이 비어있다면 종료
if [[ -z "$THEMES" ]]; then
  echo "❌ LuaLine Theme 목록을 불러올 수 없습니다."
  exit 1
fi

# 현재 설정된 theme (init.lua 의 theme = "..." 첫 번째 값)
CURRENT_THEME=$(sed -nE 's|.*theme = "([^"]*)".*|\1|p' "$LUA_FILE" | head -1)

echo "$LUA_FILE"
echo "현재 테마: ${CURRENT_THEME:-(설정 없음)}"

# fzf 또는 select로 scheme 선택
if command -v fzf >/dev/null; then
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  SELECTED=$(echo "$THEMES" | fzf --preview "\"$SELF\" --preview {}" "--preview-window=right,60%" \
    --prompt="🎨 Current Theme: $CURRENT_THEME 🌟 Select LuaLine Theme: ")
else
  echo "🌟 사용할 LuaLine Theme을 선택하세요:"
  # shellcheck disable=SC2086
  select opt in $THEMES; do
    SELECTED="$opt"
    break
  done
fi

# 선택한 scheme이 비어있으면 종료
if [[ -z "$SELECTED" ]]; then
  echo "❌ 선택이 취소되었습니다."
  exit 1
fi

# 적용
echo "✅ '$SELECTED' 프리셋을 적용합니다."

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|theme = \".*\"|theme = \"$SELECTED\"|" "$LUA_FILE"
    ;;
  *)
    sed -i "s|theme = \".*\"|theme = \"$SELECTED\"|" "$LUA_FILE"
    ;;
esac
