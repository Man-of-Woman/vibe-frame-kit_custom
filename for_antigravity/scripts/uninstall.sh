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
  fail "제거 중 문제가 발생했습니다."
}

trap on_error ERR

ANTIGRAVITY_DIR="$HOME/.gemini/config"

info "vibe-frame-kit (Antigravity 버전) 제거를 시작합니다."
info "대상 위치: $ANTIGRAVITY_DIR"

if [ ! -d "$ANTIGRAVITY_DIR" ]; then
  success "제거 대상 폴더가 존재하지 않습니다."
  exit 0
fi

TARGET_FILES_AND_DIRS=(
  "AGENTS.md"
  "agents"
  "skills"
  "config"
  "prompts"
  "templates"
  "docs"
)

for item_name in "${TARGET_FILES_AND_DIRS[@]}"; do
  target_path="$ANTIGRAVITY_DIR/$item_name"
  if [ -e "$target_path" ]; then
    rm -rf "$target_path"
    success "$item_name 을(를) 제거했습니다."
  fi
done

# 만약 폴더가 비어 있다면 폴더 자체도 삭제
if [ -d "$ANTIGRAVITY_DIR" ] && [ -z "$(ls -A "$ANTIGRAVITY_DIR")" ]; then
  rm -rf "$ANTIGRAVITY_DIR"
  success "~/.gemini/config 폴더가 비어 있어 폴더 자체를 제거했습니다."
fi

printf '\n'
success "vibe-frame-kit 제거가 완료되었습니다."
