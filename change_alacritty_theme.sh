#!/bin/bash

# 테마 파일의 섹션 안 키 값 읽기: toml_color <파일> <섹션> <키> → rrggbb
toml_color() {
  awk -v sec="[$2]" -v key="$3" '
    /^\[/ { cur = $0; sub(/[ \t]*(#.*)?$/, "", cur) }
    cur == sec && $1 == key {
      v = $0; sub(/^[^=]*=[ \t]*/, "", v)
      gsub(/[\x27" \t#]/, "", v); sub(/0x/, "", v)
      print substr(v, 1, 6); exit
    }' "$1"
}

# 테마 미리보기: preview_theme <테마 파일 경로>
preview_theme() {
  local THEME_PATH="$1" i row sec key
  [[ -f "$THEME_PATH" ]] || return 0

  BG=$(toml_color "$THEME_PATH" colors.primary background)
  FG=$(toml_color "$THEME_PATH" colors.primary foreground)
  BG=${BG:-000000}
  FG=${FG:-ffffff}

  # 팔레트 0~15: normal(black red green yellow blue magenta cyan white) + bright(같은 순서)
  local names=(black red green yellow blue magenta cyan white)
  PAL=()
  for i in {0..15}; do
    sec=colors.normal
    ((i >= 8)) && sec=colors.bright
    key=${names[i % 8]}
    PAL[i]=$(toml_color "$THEME_PATH" "$sec" "$key")
    # bright 섹션이 없는 테마는 normal 색으로 대체
    [[ -z "${PAL[i]}" ]] && PAL[i]=$(toml_color "$THEME_PATH" colors.normal "$key")
  done

  # 16진수 → "R;G;B"
  rgb() { printf '%d;%d;%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
  fgc() { printf '\033[38;2;%sm' "$(rgb "${1:-$FG}")"; }
  BGC=$(printf '\033[48;2;%sm' "$(rgb "$BG")")
  RST=$'\033[0m'
  W=${FZF_PREVIEW_COLUMNS:-60}

  printf '\033[1m%s\033[0m\n%s\n\n' "$(basename "$THEME_PATH")" "$THEME_PATH"

  # 팔레트 0~15
  for row in 0 8; do
    for i in $(seq "$row" $((row + 7))); do
      printf '%2d \033[48;2;%sm   %s ' "$i" "$(rgb "${PAL[i]:-000000}")" "$RST"
    done
    printf '\n\n'
  done

  # 샘플 코드: 테마 배경/전경/팔레트 색으로 직접 칠함
  line() { # line <보이는 길이> <색칠된 텍스트>
    printf '%s%s%s%*s%s\n' "$BGC" "$(fgc)" "$2" $((W - $1)) "" "$RST"
  }
  K=$(fgc "${PAL[5]}")
  S=$(fgc "${PAL[2]}")
  F=$(fgc "${PAL[4]}")
  N=$(fgc "${PAL[3]}")
  C=$(fgc "${PAL[8]}")
  T=$(fgc "${PAL[6]}")
  X=$(fgc)
  line 1 ""
  line 24 "  ${C}// ZiggZagg sample${X}"
  line 33 "  ${K}const${X} std = ${K}@import${X}(${S}\"std\"${X});"
  line 1 ""
  line 27 "  ${K}pub fn${X} ${F}main${X}() ${T}!void${X} {"
  line 33 "      ${K}var${X} i: ${T}usize${X} = ${N}1${X};"
  line 34 "      ${K}while${X} (i <= ${N}16${X}) : (i += ${N}1${X}) {"
  line 42 "          ${K}if${X} (i % ${N}15${X} == ${N}0${X}) {"
  line 52 "              ${K}try${X} ${F}print${X}(${S}\"ZiggZagg\\n\"${X});"
  line 11 "          }"
  line 7 "      }"
  line 3 "  }"
  line 1 ""
}

# fzf --preview 에서 재호출되는 미리보기 모드: $0 --preview <테마 파일 경로>
if [[ "$1" == "--preview" ]]; then
  preview_theme "$2"
  exit 0
fi

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

# 현재 사용 가능한 theme 목록 가져오기
THEMES=$(find "$THEME_DIR" -type f -name "*.toml" -exec basename {} \; | sort)

# 프리셋 목록이 비어있다면 종료
if [[ -z "$THEMES" ]]; then
  echo "❌ Alacritty Theme 목록을 불러올 수 없습니다."
  exit 1
fi

# 현재 설정된 theme (import 줄의 themes/<이름>.toml)
CURRENT_THEME=$(sed -nE 's|.*themes/([^"]*)".*|\1|p' "$ALACRITTY_FILE" | head -1)

echo "$ALACRITTY_FILE"
echo "현재 테마: ${CURRENT_THEME:-(설정 없음)}"

# fzf 또는 select로 theme 선택
if command -v fzf >/dev/null; then
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  SELECTED=$(echo "$THEMES" | fzf --preview "\"$SELF\" --preview \"$THEME_DIR\"/{}" "--preview-window=right,60%" \
    --prompt="🎨 Current Theme: $CURRENT_THEME 🌟 Select Alacritty Theme: ")
else
  echo "🌟 사용할 Alacritty Theme을 선택하세요:"
  select opt in $THEMES; do
    SELECTED="$opt"
    break
  done
fi

# 선택한 theme이 비어있으면 종료
if [[ -z "$SELECTED" ]]; then
  echo "❌ 선택이 취소되었습니다."
  exit 1
fi

# 적용
echo "✅ '$SELECTED' 테마를 적용합니다."

case "$OSTYPE" in
  darwin*)
    sed -i "" "s|themes\/.*\"|themes\/$SELECTED\"|" "$ALACRITTY_FILE"
    ;;
  *)
    sed -i "s|themes\/.*\"|themes\/$SELECTED\"|" "$ALACRITTY_FILE"
    ;;
esac
