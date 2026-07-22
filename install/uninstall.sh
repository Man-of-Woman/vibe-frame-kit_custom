#!/usr/bin/env bash

# vibe-frame-kit 통합 Bash 제거 스크립트
#
# Usage:
#   ./uninstall.sh -t <gemini|claude|codex>
#   ./uninstall.sh (대화식 선택)

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
  fail "제거 중 문제가 발생했습니다."
}

trap on_error ERR

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
  echo " vibe-frame-kit 통합 제거를 시작합니다."
  echo "============================================="
  echo "제거할 AI 개발 툴 환경을 선택하세요:"
  echo "1) Gemini (Antigravity)"
  echo "2) Claude (Desktop / Code CLI)"
  echo "3) Codex (Cursor 등)"
  read -rp "선택 (1-3): " Choice
  case "$Choice" in
    1) TOOL="gemini" ;;
    2) TOOL="claude" ;;
    3) TOOL="codex" ;;
    *) fail "잘못된 선택입니다. 제거를 중단합니다." ; exit 1 ;;
  esac
fi

# 변수 테이블 바인딩
case "$TOOL" in
  gemini)
    INSTALL_BASE_DIR="$HOME/.gemini/config"
    RULES_FILE="AGENTS.md"
    ;;
  claude)
    INSTALL_BASE_DIR="$HOME/.claude"
    RULES_FILE="CLAUDE.md"
    ;;
  codex)
    INSTALL_BASE_DIR="$HOME/.codex"
    RULES_FILE="AGENTS.md"
    ;;
  *)
    fail "지원하지 않는 툴 유형입니다: $TOOL"
    exit 1
    ;;
esac

info "vibe-frame-kit ($TOOL 버전) 제거를 시작합니다."
info "대상 위치: $INSTALL_BASE_DIR"

if [ ! -d "$INSTALL_BASE_DIR" ]; then
  success "제거 대상 폴더가 존재하지 않아 삭제할 항목이 없습니다."
  exit 0
fi

# 삭제할 파일 및 폴더 목록
TARGET_ITEMS=(
  "$RULES_FILE"
  "RULES.md"
  "agents"
  "skills"
  "config"
  "prompts"
  "templates"
  "docs"
  "study"
)

for item_name in "${TARGET_ITEMS[@]}"; do
  target_path="$INSTALL_BASE_DIR/$item_name"
  if [ -e "$target_path" ]; then
    rm -rf "$target_path"
    success "$item_name 항목을 제거했습니다."
  fi
done

# 백업 폴더를 제외하고 폴더가 비어 있으면 폴더 자체도 삭제
if [ -d "$INSTALL_BASE_DIR" ] && [ -z "$(ls -A "$INSTALL_BASE_DIR" | grep -v 'backup' || true)" ]; then
  # 완전히 비어있거나 backup 폴더만 있으면, backup이 아닌 파일이 완전히 없는 경우
  # 만약 진짜 아무 파일도 없으면 폴더 제거
  if [ -z "$(ls -A "$INSTALL_BASE_DIR" || true)" ]; then
    rmdir "$INSTALL_BASE_DIR"
    success "비어 있는 $INSTALL_BASE_DIR 폴더를 제거했습니다."
  fi
else
  info "$INSTALL_BASE_DIR 폴더에 백업 또는 개인용 다른 파일이 남아있어 폴더를 유지합니다."
fi

printf '\n'
success "vibe-frame-kit ($TOOL 버전) 제거가 완료되었습니다."
printf '\n'
