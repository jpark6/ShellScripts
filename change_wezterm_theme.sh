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

# 현재 사용 가능한 scheme 목록 가져오기
SCHEMES=$(sed "s|\r||" "$SCHEMES_FILE")

# 프리셋 목록이 비어있다면 종료
if [[ -z "$SCHEMES" ]]; then
  echo "❌ WezTerm Scheme 목록을 불러올 수 없습니다."
  exit 1
fi

# 현재 설정된 scheme (첫 번째 color_scheme 값)
CURRENT_SCHEME=$(awk -F '=' '/color_scheme/ { print $2; exit }' "$WEZTERM_FILE" | sed 's|^[ "]*||; s|[ "]*$||')

echo "$WEZTERM_FILE"
echo "현재 테마: ${CURRENT_SCHEME:-(설정 없음)}"

# fzf 또는 select로 scheme 선택
if command -v fzf >/dev/null; then
  SELECTED=$(echo "$SCHEMES" | fzf --prompt="🎢 Current Scheme: $CURRENT_SCHEME 🌟 Select WezTerm Scheme: ")
else
  echo "🌟 사용할 WezTerm Scheme을 선택하세요:"
  OLD_IFS="$IFS"
  IFS=$'\n' # scheme 이름의 공백으로 쪼개지지 않도록
  # shellcheck disable=SC2086
  select opt in $SCHEMES; do
    SELECTED="$opt"
    break
  done
  IFS="$OLD_IFS"
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
    sed -i "" "s|config.color_scheme = \".*\"|config.color_scheme = \"$SELECTED\"|" "$WEZTERM_FILE"
    ;;
  *)
    sed -i "s|config.color_scheme = \".*\"|config.color_scheme = \"$SELECTED\"|" "$WEZTERM_FILE"
    ;;
esac
