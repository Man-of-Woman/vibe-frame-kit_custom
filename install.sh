#!/usr/bin/env bash

# vibe-frame-kit 통합 Bash 설치 스크립트
#
# Usage:
#   ./install.sh -t <gemini|claude|codex>
#   ./install.sh (대화식 선택)

set -euo pipefail

info() {
  printf '\033[36m[INFO]\033[0m %s\n' "$1"
}

success() {
  printf '\033[32m[OK]\033[0m %s\n' "$1"
}

fail() {
  printf '\033[31m[ERROR]\033[0m %s\n' "$1"
}

on_error() {
  fail "설치 중 문제가 발생했습니다."
  printf '\033[33m확인해볼 내용:\033[0m\n'
  printf -- '- 이 스크립트를 vibe-frame-kit 저장소 루트 안에서 실행했는지 확인하세요.\n'
  printf -- '- 실행 권한이 없다면 다음 명령을 먼저 실행하세요: chmod +x install.sh\n'
  printf -- '- 설치 폴더에 파일을 쓸 권한이 있는지 확인하세요.\n'
}

trap on_error ERR

# 템플릿 치환 함수 (Python3 우선, sed fallback)
replace_variables() {
  local src_file="$1"
  local dest_file="$2"
  
  cp "$src_file" "$dest_file"
  
  if command -v python3 &>/dev/null; then
    python3 -c "
import sys
try:
    with open('$dest_file', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    for k, v in [
        ('{{AGENT_NAME}}', '$AGENT_NAME'),
        ('{{INSTALL_PATH}}', '$INSTALL_PATH'),
        ('{{CONFIG_FILE}}', '$CONFIG_FILE'),
        ('{{RULES_FILE}}', '$RULES_FILE')
    ]:
        content = content.replace(k, v)
    with open('$dest_file', 'w', encoding='utf-8') as f:
        f.write(content)
except Exception as e:
    sys.exit(1)
"
  else
    # Python이 없는 경우 (sed 백업 옵션 호환성 처리)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$dest_file"
      sed -i '' "s|{{INSTALL_PATH}}|$INSTALL_PATH|g" "$dest_file"
      sed -i '' "s/{{CONFIG_FILE}}/$CONFIG_FILE/g" "$dest_file"
      sed -i '' "s/{{RULES_FILE}}/$RULES_FILE/g" "$dest_file"
    else
      sed -i "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$dest_file"
      sed -i "s|{{INSTALL_PATH}}|$INSTALL_PATH|g" "$dest_file"
      sed -i "s/{{CONFIG_FILE}}/$CONFIG_FILE/g" "$dest_file"
      sed -i "s/{{RULES_FILE}}/$RULES_FILE/g" "$dest_file"
    fi
  fi
}

# 재귀 복사 및 치환 배포 함수
copy_and_replace_directory() {
  local src_dir="$1"
  local dest_dir="$2"
  
  mkdir -p "$dest_dir"
  
  # 모든 하위 파일 및 폴더를 탐색
  find "$src_dir" -mindepth 1 | while read -r item; do
    local rel_path="${item#$src_dir/}"
    local dest_item="$dest_dir/$rel_path"
    
    # RULES.md ➡️ RULES_FILE 명칭 변경
    if [ "$rel_path" = "RULES.md" ]; then
      dest_item="$dest_dir/$RULES_FILE"
    # common.config.sample.toml ➡️ CONFIG_FILE 명칭 변경
    elif [ "$rel_path" = "config/common.config.sample.toml" ]; then
      dest_item="$dest_dir/config/$CONFIG_FILE"
    fi
    
    if [ -d "$item" ]; then
      mkdir -p "$dest_item"
    elif [ -f "$item" ]; then
      local ext="${item##*.}"
      # md, toml, txt 파일인 경우 치환 복사 진행
      if [ "$ext" = "md" ] || [ "$ext" = "toml" ] || [ "$ext" = "txt" ]; then
        local parent_dir
        parent_dir="$(dirname "$dest_item")"
        mkdir -p "$parent_dir"
        replace_variables "$item" "$dest_item"
      else
        # 바이너리 등은 일반 복사
        local parent_dir
        parent_dir="$(dirname "$dest_item")"
        mkdir -p "$parent_dir"
        cp "$item" "$dest_item"
      fi
    fi
  done
}

TOOL=""

# 파라미터 처리 (-t <tool>)
while getopts "t:" opt; do
  case $opt in
    t) TOOL="$OPTARG" ;;
    *) fail "잘못된 옵션입니다." ; exit 1 ;;
  esac
done

# 대화식 선택 루프
if [ -z "$TOOL" ]; then
  echo "============================================="
  echo " vibe-frame-kit 통합 설치를 시작합니다."
  echo "============================================="
  echo "설치할 AI 개발 툴 환경을 선택하세요:"
  echo "1) Gemini (Antigravity)"
  echo "2) Claude (Desktop / Code CLI)"
  echo "3) Codex (Cursor 등)"
  read -rp "선택 (1-3): " Choice
  case "$Choice" in
    1) TOOL="gemini" ;;
    2) TOOL="claude" ;;
    3) TOOL="codex" ;;
    *) fail "잘못된 선택입니다. 설치를 중단합니다." ; exit 1 ;;
  esac
fi

# 변수 테이블 바인딩
case "$TOOL" in
  gemini)
    INSTALL_BASE_DIR="$HOME/.gemini/config"
    AGENT_NAME="Gemini"
    INSTALL_PATH="~/.gemini/config"
    CONFIG_FILE="gemini.config.sample.toml"
    RULES_FILE="AGENTS.md"
    ;;
  claude)
    INSTALL_BASE_DIR="$HOME/.claude"
    AGENT_NAME="Claude"
    INSTALL_PATH="~/.claude"
    CONFIG_FILE="claude.config.sample.toml"
    RULES_FILE="CLAUDE.md"
    ;;
  codex)
    INSTALL_BASE_DIR="$HOME/.codex"
    AGENT_NAME="Codex"
    INSTALL_PATH="~/.codex"
    CONFIG_FILE="codex.config.sample.toml"
    RULES_FILE="AGENTS.md"
    ;;
  *)
    fail "지원하지 않는 툴 유형입니다: $TOOL"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

info "vibe-frame-kit ($AGENT_NAME 환경) 설치를 시작합니다."
info "저장소 위치: $REPO_ROOT"
info "설치 위치: $INSTALL_BASE_DIR"

mkdir -p "$INSTALL_BASE_DIR"

SOURCE_COMMON_DIR="$REPO_ROOT/common"
if [ ! -d "$SOURCE_COMMON_DIR" ]; then
  fail "공통 소스 폴더를 찾을 수 없습니다: $SOURCE_COMMON_DIR"
  exit 1
fi

# 기존 디렉토리 백업
DIRECTORIES_TO_COPY=("agents" "skills" "config" "prompts" "templates" "docs")
for dir_name in "${DIRECTORIES_TO_COPY[@]}"; do
  target_dir="$INSTALL_BASE_DIR/$dir_name"
  if [ -d "$target_dir" ]; then
    BACKUP_DIR="$INSTALL_BASE_DIR/${dir_name}.backup.$TIMESTAMP"
    cp -R "$target_dir" "$BACKUP_DIR"
    success "기존 $dir_name 폴더를 백업했습니다: $BACKUP_DIR"
  fi
done

# 기존 규칙 파일 백업
TARGET_RULES_FILE="$INSTALL_BASE_DIR/$RULES_FILE"
if [ -f "$TARGET_RULES_FILE" ]; then
  BACKUP_RULES_PATH="$INSTALL_BASE_DIR/${RULES_FILE}.backup.$TIMESTAMP"
  cp "$TARGET_RULES_FILE" "$BACKUP_RULES_PATH"
  success "기존 $RULES_FILE 파일을 백업했습니다: $BACKUP_RULES_PATH"
fi

# 복사 및 변수 치환 배포
copy_and_replace_directory "$SOURCE_COMMON_DIR" "$INSTALL_BASE_DIR"
success "프레임워크 코어 파일 배포 및 템플릿 치환이 완료되었습니다."

printf '\n'
success "vibe-frame-kit ($AGENT_NAME 버전) 설치가 완료되었습니다."
printf '\033[32m설치된 항목:\033[0m\n'
printf -- '- %s/%s\n' "$INSTALL_PATH" "$RULES_FILE"
printf -- '- %s/agents/\n' "$INSTALL_PATH"
printf -- '- %s/skills/\n' "$INSTALL_PATH"
printf -- '- %s/config/\n' "$INSTALL_PATH"
printf -- '- %s/prompts/\n' "$INSTALL_PATH"
printf -- '- %s/templates/\n' "$INSTALL_PATH"
printf -- '- %s/docs/\n' "$INSTALL_PATH"
printf '\n'
