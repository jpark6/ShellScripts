#!/bin/bash

case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      WEZTERM_FILE="/mnt/c/Users/banseok/.wezterm.lua"
    fi
    ;;
  *)
    WEZTERM_FILE="$HOME/Repos/dotfiles/.wezterm.lua"
    ;;
esac

FONTS=$(fc-list : family | awk -F',' ' $1~/Nerd Font/ { print $1 } ' | sort | uniq )

CURRENT_FONT=$(awk -F '[(),"]' '/wezterm.font/ { print $3 }' $WEZTERM_FILE | sed 's| Nerd Font||')

# 프리셋 목록이 비어있다면 종료
if [ -z "$FONTS" ]; then
  echo "❌ WezTerm Font 목록을 불러올 수 없습니다."
  exit 1
fi


# fzf 또는 select로 font 선택
if command -v fzf > /dev/null; then
  SELECTED=$(echo "$FONTS" | sed "s|\r||" | fzf --prompt="🖋 CurrentFont: $CURENT_FONT 🌟 Select WezTerm Font: ")
else
  # 기본 select 메뉴
  echo "🌟 사용할 WezTerm Font를 선택하세요:"
  select opt in $FONTS; do
    SELECTED="$opt"
    break
  done
fi

# 선택한 font이 비어있으면 종료
if [ -z "$SELECTED" ]; then
  echo "❌ 선택이 취소되었습니다."
  exit 1
fi

# 적용
echo "✅ '$SELECTED' 폰트를 적용합니다."

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|wezterm.font(\".*\",|wezterm.font(\"$SELECTED\",|" $WEZTERM_FILE
    ;;
  *)
    sed -i "s|wezterm.font(\".*\",|wezterm.font(\"$SELECTED\",|" $WEZTERM_FILE
    ;;
esac
