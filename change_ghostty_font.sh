#!/bin/bash

# fzf --preview 에서 재호출되는 미리보기 모드: $0 --preview <폰트 패밀리>
# 폰트 파일로 샘플 텍스트를 PNG로 그려 kitty 이미지 프로토콜(kitten icat)로 출력
if [ "$1" = "--preview" ]; then
  FAMILY="$2"
  FONT_FILE=$(fc-match -f '%{family}\t%{file}' "$FAMILY:style=Regular" 2>/dev/null | awk -F'\t' -v f="$FAMILY" 'index($1, f) { print $2 }')
  PNG=$(mktemp -t ghostty_font).png

  if [ -n "$FONT_FILE" ] && python3 - "$FONT_FILE" "$FAMILY" "$PNG" 2>/dev/null <<'EOF'
import sys
from PIL import Image, ImageDraw, ImageFont

font_file, family, out = sys.argv[1:4]
lines = [
    (family, 44),
    ("The quick brown fox jumps over the lazy dog", 34),
    ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", 34),
    ("abcdefghijklmnopqrstuvwxyz 0123456789", 34),
    ("{ } [ ] ( ) => -> != == === <= >= && ||", 34),
    ("           ", 34),
]
img = Image.new("RGB", (1400, 40 + sum(s + 24 for _, s in lines)), "#1e1e2e")
draw = ImageDraw.Draw(img)
y = 24
for text, size in lines:
    draw.text((30, y), text, font=ImageFont.truetype(font_file, size), fill="#cdd6f4")
    y += size + 24
img.save(out)
EOF
  then
    if [ -n "$GHOSTTY_RESOURCES_DIR" ] && command -v kitten >/dev/null; then
      DIM=${FZF_PREVIEW_COLUMNS:-60}x${FZF_PREVIEW_LINES:-20}
      # 마지막 줄(개행 없는 reset 코드)은 fzf가 혼동하므로 제거 후 이전 줄 끝에 붙임
      kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="$DIM@0x0" "$PNG" |
        sed '$d' | sed $'$s/$/\e[m/'
    else
      echo "$FAMILY"
      echo "(이미지 미리보기는 Ghostty + kitten 필요)"
    fi
  else
    echo "$FAMILY"
    echo "(폰트 파일을 찾거나 렌더링할 수 없습니다)"
  fi
  rm -f "$PNG"
  exit 0
fi

GHOSTTY_FILE="$HOME/.config/ghostty/config"

# 설정 파일이 없으면 생성
if [ ! -f "$GHOSTTY_FILE" ]; then
  mkdir -p "$(dirname "$GHOSTTY_FILE")"
  touch "$GHOSTTY_FILE"
fi

# ghostty 바이너리 찾기 (macOS는 PATH에 없을 수 있음)
GHOSTTY_BIN=""
if command -v ghostty >/dev/null; then
  GHOSTTY_BIN="ghostty"
elif [ -x "/Applications/Ghostty.app/Contents/MacOS/ghostty" ]; then
  GHOSTTY_BIN="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

# Nerd Font 목록 수집: fc-list 우선, 없으면 ghostty +list-fonts
if command -v fc-list >/dev/null; then
  FONTS=$(fc-list : family | awk -F',' '$1 ~ /Nerd Font/ { print $1 }' | sed "s|\r||" | sort -u)
elif [ -n "$GHOSTTY_BIN" ]; then
  # +list-fonts 출력에서 들여쓰기 없는 줄이 패밀리 이름
  FONTS=$("$GHOSTTY_BIN" +list-fonts 2>/dev/null | awk '/^[^ \t]/ && /Nerd Font/' | sort -u)
fi

# 현재 설정된 폰트 (첫 번째 font-family 값)
CURRENT_FONT=$(awk '
  /^[[:space:]]*font-family[[:space:]]*=/ {
    sub(/^[^=]*=[[:space:]]*/, "")
    gsub(/^"|"[[:space:]]*$/, "")
    print
    exit
  }' "$GHOSTTY_FILE")

echo "$GHOSTTY_FILE"
echo "현재 폰트: ${CURRENT_FONT:-(설정 없음)}"

# 폰트 목록이 비어있다면 종료
if [ -z "$FONTS" ]; then
  echo "❌ Nerd Font 목록을 불러올 수 없습니다."
  exit 1
fi

# fzf 또는 select로 폰트 선택
if command -v fzf >/dev/null; then
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  SELECTED=$(echo "$FONTS" | fzf --preview "\"$SELF\" --preview {}" --preview-window=right,60% \
    --prompt="🖋 CurrentFont: $CURRENT_FONT 🌟 Select Ghostty Font: ")
else
  echo "🌟 사용할 Ghostty Font를 선택하세요:"
  OLD_IFS="$IFS"
  IFS=$'\n' # 폰트 이름의 공백으로 쪼개지지 않도록
  select opt in $FONTS; do
    SELECTED="$opt"
    break
  done
  IFS="$OLD_IFS"
fi

# 선택한 폰트가 비어있으면 종료
if [ -z "$SELECTED" ]; then
  echo "❌ 선택이 취소되었습니다."
  exit 1
fi

# 적용: 첫 번째 font-family 줄을 교체, 없으면 끝에 추가
echo "✅ '$SELECTED' 폰트를 적용합니다."

TMP_FILE=$(mktemp)
awk -v font="$SELECTED" '
  !done && /^[[:space:]]*font-family[[:space:]]*=/ {
    print "font-family = \"" font "\""
    done = 1
    next
  }
  { print }
  END {
    if (!done) print "font-family = \"" font "\""
  }' "$GHOSTTY_FILE" >"$TMP_FILE" &&
  cat "$TMP_FILE" >"$GHOSTTY_FILE" # cat으로 덮어써서 심볼릭 링크 유지
rm -f "$TMP_FILE"

echo "🔄 Ghostty에서 설정 리로드(macOS: ⌘⇧, / Linux: Ctrl+Shift+,) 하거나 새 창을 여세요."
