#!/bin/bash

# 프리셋 미리보기: preview_preset <프리셋 이름>
# 임시 설정 파일로 실제 프롬프트를 렌더링 (STARSHIP_SHELL이 있으면 zsh/bash용 %{ %} 감싸기가 붙으므로 해제)
preview_preset() {
  local tmp cols=${FZF_PREVIEW_COLUMNS:-60}
  tmp=$(mktemp -t starship_preset).toml
  starship preset "$1" >"$tmp" 2>/dev/null

  printf '\033[1m%s\033[0m\n\n' "$1"
  env -u STARSHIP_SHELL STARSHIP_CONFIG="$tmp" starship prompt --terminal-width="$cols" 2>/dev/null
  printf '\033[0m\n'
  rm -f "$tmp"
}

# fzf --preview 에서 재호출되는 미리보기 모드: $0 --preview <프리셋 이름>
if [[ "$1" == "--preview" ]]; then
  preview_preset "$2"
  exit 0
fi

STARSHIP_FILE="$HOME/.config/starship.toml"

# 현재 사용 가능한 preset 목록 가져오기
PRESETS=$(starship preset --list)

# 프리셋 목록이 비어있다면 종료
if [[ -z "$PRESETS" ]]; then
  echo "❌ starship preset 목록을 불러올 수 없습니다."
  exit 1
fi

# 현재 설정과 내용이 같은 프리셋 찾기 (starship.toml에는 프리셋 이름이 기록되지 않음)
CURRENT_PRESET=""
if [[ -f "$STARSHIP_FILE" ]]; then
  while IFS= read -r name; do
    if [[ "$(starship preset "$name" 2>/dev/null)" == "$(cat "$STARSHIP_FILE")" ]]; then
      CURRENT_PRESET="$name"
      break
    fi
  done <<<"$PRESETS"
fi

echo "$STARSHIP_FILE"
if [[ -f "$STARSHIP_FILE" ]]; then
  echo "현재 프리셋: ${CURRENT_PRESET:-(프리셋과 일치하지 않음)}"
else
  echo "현재 프리셋: (설정 파일 없음)"
fi

# fzf 또는 select로 preset 선택
if command -v fzf >/dev/null; then
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  SELECTED=$(echo "$PRESETS" | fzf --preview "\"$SELF\" --preview {}" "--preview-window=right,60%" \
    --prompt="🌟 Current: ${CURRENT_PRESET:-none} 🌟 Select Starship Preset: ")
else
  echo "🌟 사용할 Starship preset을 선택하세요:"
  # shellcheck disable=SC2086
  select opt in $PRESETS; do
    SELECTED="$opt"
    break
  done
fi

# 선택한 preset이 비어있으면 종료
if [[ -z "$SELECTED" ]]; then
  echo "❌ 선택이 취소되었습니다."
  exit 1
fi

# 적용
echo "✅ '$SELECTED' 프리셋을 적용합니다..."

# 기존 설정이 프리셋과 다른 내용이면 덮어쓰기 전에 백업
if [[ -f "$STARSHIP_FILE" && -z "$CURRENT_PRESET" ]]; then
  cp "$STARSHIP_FILE" "$STARSHIP_FILE.bak"
  echo "💾 기존 설정을 $STARSHIP_FILE.bak 으로 백업했습니다."
fi

mkdir -p "$(dirname "$STARSHIP_FILE")"
# cat으로 덮어써서 심볼릭 링크 유지
starship preset "$SELECTED" | cat >"$STARSHIP_FILE"

echo "✨ Starship preset '$SELECTED' 이(가) 적용되었습니다!"
