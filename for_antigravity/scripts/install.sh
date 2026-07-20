#!/usr/bin/env bash

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
  printf -- '- 이 스크립트를 vibe-frame-kit 저장소 안에서 실행했는지 확인하세요.\n'
  printf -- '- 실행 권한이 없다면 다음 명령을 먼저 실행하세요:\n'
  printf '  chmod +x scripts/install.sh\n'
  printf -- '- ~/.gemini/config 폴더에 파일을 쓸 권한이 있는지 확인하세요.\n'
}

trap on_error ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANTIGRAVITY_DIR="$HOME/.gemini/config"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

info "vibe-frame-kit (Antigravity 버전) 설치를 시작합니다."
info "저장소 위치: $REPO_ROOT"
info "설치 위치: $ANTIGRAVITY_DIR"

mkdir -p "$ANTIGRAVITY_DIR"
success "~/.gemini/config 폴더를 준비했습니다."

SOURCE_AGENTS_FILE="$REPO_ROOT/AGENTS.md"
TARGET_AGENTS_FILE="$ANTIGRAVITY_DIR/AGENTS.md"

if [ ! -f "$SOURCE_AGENTS_FILE" ]; then
  fail "원본 AGENTS.md 파일을 찾을 수 없습니다: $SOURCE_AGENTS_FILE"
  exit 1
fi

if [ -f "$TARGET_AGENTS_FILE" ]; then
  BACKUP_PATH="$ANTIGRAVITY_DIR/AGENTS.md.backup.$TIMESTAMP"
  cp "$TARGET_AGENTS_FILE" "$BACKUP_PATH"
  success "기존 ~/.gemini/config/AGENTS.md 파일을 백업했습니다: $BACKUP_PATH"
fi

cp "$SOURCE_AGENTS_FILE" "$TARGET_AGENTS_FILE"
success "AGENTS.md 파일을 설치했습니다."

DIRECTORIES_TO_COPY=(
  "agents"
  "skills"
  "config"
  "prompts"
  "templates"
  "docs"
)

for directory_name in "${DIRECTORIES_TO_COPY[@]}"; do
  source_dir="$REPO_ROOT/$directory_name"
  target_dir="$ANTIGRAVITY_DIR/$directory_name"

  if [ ! -d "$source_dir" ]; then
    fail "원본 폴더를 찾을 수 없습니다: $source_dir"
    exit 1
  fi

  if [ -d "$target_dir" ]; then
    BACKUP_DIR="$ANTIGRAVITY_DIR/${directory_name}.backup.$TIMESTAMP"
    cp -R "$target_dir" "$BACKUP_DIR"
    success "기존 ~/.gemini/config/$directory_name 폴더를 백업했습니다: $BACKUP_DIR"
  fi

  mkdir -p "$target_dir"
  cp -R "$source_dir"/. "$target_dir"/
  success "$directory_name 폴더를 설치했습니다."
done

printf '\n'
success "vibe-frame-kit (Antigravity 버전) 설치가 완료되었습니다."
printf '\033[32m설치된 항목:\033[0m\n'
printf -- '- ~/.gemini/config/AGENTS.md\n'
printf -- '- ~/.gemini/config/agents/\n'
printf -- '- ~/.gemini/config/skills/\n'
printf -- '- ~/.gemini/config/config/\n'
printf -- '- ~/.gemini/config/prompts/\n'
printf -- '- ~/.gemini/config/templates/\n'
printf -- '- ~/.gemini/config/docs/\n'
printf '\n'
printf '다음에 실행 권한이 필요하면 아래 명령을 사용하세요:\n'
printf '  chmod +x scripts/install.sh\n'
