#!/bin/bash

# 테마 미리보기: preview_theme <테마 파일 경로> [라벨]
preview_theme() {
  local THEME_PATH="$1" LABEL="$2" i row c
  [ -f "$THEME_PATH" ] || return 0

  # 테마 파일에서 색상 읽기
  BG=$(awk -F'[ =]+' '$1=="background"{print $2}' "$THEME_PATH")
  FG=$(awk -F'[ =]+' '$1=="foreground"{print $2}' "$THEME_PATH")
  BG=${BG#\#}
  FG=${FG#\#}
  BG=${BG:-000000}
  FG=${FG:-ffffff}
  PAL=()
  for i in $(seq 0 15); do
    c=$(awk -F'[ =]+' -v n="$i" '$1=="palette" && $2==n {print $3}' "$THEME_PATH")
    PAL[i]=${c#\#}
  done

  # 16진수 → "R;G;B"
  rgb() { printf '%d;%d;%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
  fgc() { printf '\033[38;2;%sm' "$(rgb "${1:-$FG}")"; }
  BGC=$(printf '\033[48;2;%sm' "$(rgb "$BG")")
  RST=$'\033[0m'
  W=${FZF_PREVIEW_COLUMNS:-60}

  printf '\033[1m%s%s\033[0m\n%s\n\n' "${LABEL:+[$LABEL] }" "$(basename "$THEME_PATH")" "$THEME_PATH"

  # 팔레트 0~15
  for row in 0 8; do
    for i in $(seq $row $((row + 7))); do
      printf '%2d \033[48;2;%sm   %s ' "$i" "$(rgb "${PAL[$i]:-000000}")" "$RST"
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

# fzf --preview 에서 재호출되는 미리보기 모드: $0 --preview <경로> [<light 경로>]
# 경로가 둘이면 앞은 dark, 뒤는 light 로 표시
if [ "$1" = "--preview" ]; then
  if [ -n "$3" ]; then
    preview_theme "$2" dark
    echo
    preview_theme "$3" light
  else
    preview_theme "$2"
  fi
  exit 0
fi

GHOSTTY_FILE="$HOME/.config/ghostty/config"
HISTORY_FILE="$HOME/.config/ghostty/theme_history" # 형식: 시각<TAB>모드<TAB>theme 값

# 설정/이력 파일이 없으면 생성
if [ ! -f "$GHOSTTY_FILE" ]; then
  mkdir -p "$(dirname "$GHOSTTY_FILE")"
  touch "$GHOSTTY_FILE"
fi
[ -f "$HISTORY_FILE" ] || touch "$HISTORY_FILE"

# ghostty 바이너리 찾기 (macOS는 PATH에 없을 수 있음)
GHOSTTY_BIN=""
if command -v ghostty >/dev/null; then
  GHOSTTY_BIN="ghostty"
elif [ -x "/Applications/Ghostty.app/Contents/MacOS/ghostty" ]; then
  GHOSTTY_BIN="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

if [ -z "$GHOSTTY_BIN" ]; then
  echo "❌ ghostty 를 찾을 수 없습니다."
  exit 1
fi

# 테마 목록 (--plain --path: "이름 (resources|user) 경로" → "이름<TAB>경로", 출처 표시는 제거)
THEME_LINES=$("$GHOSTTY_BIN" +list-themes --plain --path 2>/dev/null | sed -E -e "s|\r||" -e 's/^(.*) \((resources|user)\) (\/.*)$/\1\t\3/' | sort -u)
THEMES=$(echo "$THEME_LINES" | cut -f1)
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# 현재 설정된 테마 (첫 번째 theme 값, 예: dark:X,light:Y 또는 X)
CURRENT_THEME=$(awk '
  /^[[:space:]]*theme[[:space:]]*=/ {
    sub(/^[^=]*=[[:space:]]*/, "")
    gsub(/^"|"[[:space:]]*$/, "")
    print
    exit
  }' "$GHOSTTY_FILE")

# dark / light 현재 값 추출 (단일 테마면 둘 다 같은 값으로 취급)
CURRENT_DARK=$(echo "$CURRENT_THEME" | tr ',' '\n' | sed -n 's/^[[:space:]]*dark:[[:space:]]*//p' | head -1)
CURRENT_LIGHT=$(echo "$CURRENT_THEME" | tr ',' '\n' | sed -n 's/^[[:space:]]*light:[[:space:]]*//p' | head -1)
if [ -z "$CURRENT_DARK" ] && [ -z "$CURRENT_LIGHT" ]; then
  CURRENT_DARK="$CURRENT_THEME"
  CURRENT_LIGHT="$CURRENT_THEME"
fi

echo "$GHOSTTY_FILE"
echo "현재 테마: ${CURRENT_THEME:-(설정 없음)}"

# 테마 목록이 비어있다면 종료
if [ -z "$THEMES" ]; then
  echo "❌ Ghostty 테마 목록을 불러올 수 없습니다."
  exit 1
fi

# fzf 또는 select로 선택: pick <프롬프트> [preview]
# stdin: 탭 구분 줄(1열이 표시 이름, 2·3열은 미리보기용 테마 경로) → 선택한 줄 전체를 출력
pick() {
  local prompt="$1" use_preview="$2"
  if command -v fzf >/dev/null; then
    local args=(--delimiter=$'\t' --with-nth=1 --prompt="$prompt")
    if [ -n "$use_preview" ]; then
      args+=(--preview "\"$SELF\" --preview {2} {3}" "--preview-window=right,60%")
    fi
    fzf "${args[@]}"
  else
    local lines=() names=() line name
    while IFS= read -r line; do
      lines+=("$line")
      names+=("${line%%$'\t'*}")
    done
    echo "🌟 $prompt" >&2
    select name in "${names[@]}"; do
      if [ -n "$name" ]; then
        echo "${lines[REPLY - 1]}"
        break
      fi
    done </dev/tty
  fi
}

# 테마 이름 → 파일 경로
theme_path() {
  echo "$THEME_LINES" | awk -F'\t' -v n="$1" '$1==n { print $2; exit }'
}

# 테마 하나 선택: select_theme <모드(dark/light)> <현재 값>
select_theme() {
  echo "$THEME_LINES" | pick "🎨 Current $1: $2 🌟 Select Ghostty $1 Theme: " preview | cut -f1
}

# 이력 목록 (최신순): "표시<TAB>경로1<TAB>경로2<TAB>모드<TAB>theme 값"
history_lines() {
  local ts mode value d l p1 p2
  awk '{ a[NR] = $0 } END { for (i = NR; i > 0; i--) print a[i] }' "$HISTORY_FILE" |
    while IFS=$'\t' read -r ts mode value; do
      if [ "$mode" = "system" ]; then
        d=${value#dark:}
        d=${d%%,light:*}
        l=${value##*,light:}
        p1=$(theme_path "$d")
        p2=$(theme_path "$l")
      else
        p1=$(theme_path "$value")
        p2=""
      fi
      printf '%s  [%s]  %s\t%s\t%s\t%s\t%s\n' "$ts" "$mode" "$value" "$p1" "$p2" "$mode" "$value"
    done
}

# 이력 기록: 직전 기록과 같으면 생략
record_history() {
  local last
  last=$(tail -1 "$HISTORY_FILE" | cut -f2,3)
  [ "$last" = "$1"$'\t'"$2" ] && return
  printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >>"$HISTORY_FILE"
}

# 적용: 첫 번째 theme 줄을 교체, 없으면 끝에 추가 (apply_theme <모드> <theme 값>)
apply_theme() {
  echo "✅ 'theme = $2' 를 적용합니다."

  local tmp
  tmp=$(mktemp)
  awk -v theme="$2" '
    !done && /^[[:space:]]*theme[[:space:]]*=/ {
      print "theme = " theme
      done = 1
      next
    }
    { print }
    END {
      if (!done) print "theme = " theme
    }' "$GHOSTTY_FILE" >"$tmp" &&
    cat "$tmp" >"$GHOSTTY_FILE" # cat으로 덮어써서 심볼릭 링크 유지
  rm -f "$tmp"

  record_history "$1" "$2"
}

cancel() {
  echo "❌ 선택이 취소되었습니다."
  exit 1
}

# 모드 선택
MODE=$(printf 'history\nsystem\nfixed\n' | pick "🎨 Current: ${CURRENT_THEME:-(없음)} 🌟 Select Mode: " | cut -f1)
[ -z "$MODE" ] && cancel

case "$MODE" in
  history)
    HISTORY_LIST=$(history_lines)
    if [ -z "$HISTORY_LIST" ]; then
      echo "❌ 변경 이력이 없습니다."
      exit 1
    fi
    LINE=$(echo "$HISTORY_LIST" | pick "🕘 Select History: " preview)
    [ -z "$LINE" ] && cancel
    apply_theme "$(echo "$LINE" | cut -f4)" "$(echo "$LINE" | cut -f5)"
    ;;
  system)
    SELECTED_DARK=$(select_theme "dark" "$CURRENT_DARK")
    [ -z "$SELECTED_DARK" ] && cancel
    SELECTED_LIGHT=$(select_theme "light" "$CURRENT_LIGHT")
    [ -z "$SELECTED_LIGHT" ] && cancel
    apply_theme system "dark:$SELECTED_DARK,light:$SELECTED_LIGHT"
    ;;
  fixed)
    SELECTED=$(select_theme "fixed" "$CURRENT_THEME")
    [ -z "$SELECTED" ] && cancel
    apply_theme fixed "$SELECTED"
    ;;
esac

echo "🔄 Ghostty에서 설정 리로드(macOS: ⌘⇧, / Linux: Ctrl+Shift+,) 하거나 새 창을 여세요."
