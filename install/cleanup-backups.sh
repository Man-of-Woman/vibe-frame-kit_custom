#!/usr/bin/env bash

# vibe-frame-kit 백업 파일/폴더 확인 및 승인 기반 정리 스크립트
set -euo pipefail

TOOLS=("gemini" "claude" "codex")
if [ "$#" -gt 0 ]; then
  TOOLS=("$@")
fi

backup_roots=()
for tool in "${TOOLS[@]}"; do
  case "$tool" in
    gemini) backup_roots+=("$HOME/.gemini/config") ;;
    claude) backup_roots+=("$HOME/.claude") ;;
    codex) backup_roots+=("$HOME/.codex" "$HOME/.agents") ;;
    *)
      printf '[ERROR] 지원하지 않는 도구입니다: %s\n' "$tool" >&2
      exit 1
      ;;
  esac
done

backup_items=()
for root in "${backup_roots[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r -d '' item; do
    backup_items+=("$item")
  done < <(find "$root" -mindepth 1 -maxdepth 1 \( -name '*.backup.*' -o -name 'backup.*' \) -print0)
done

if [ "${#backup_items[@]}" -eq 0 ]; then
  printf '백업 파일 또는 폴더를 찾지 못했습니다.\n'
  exit 0
fi

printf '발견된 백업 파일/폴더: %d개\n\n' "${#backup_items[@]}"
for index in "${!backup_items[@]}"; do
  item="${backup_items[$index]}"
  if [ -d "$item" ]; then
    kind='폴더'
  else
    kind='파일'
  fi
  printf '[%d] %s | %s\n' "$((index + 1))" "$kind" "$item"
done

printf '\n위 목록의 백업만 삭제합니다. 취소하려면 아무 값이나 입력하세요.\n'
read -r -p '삭제하려면 DELETE를 정확히 입력하세요: ' confirmation
if [ "$confirmation" != 'DELETE' ]; then
  printf '삭제를 취소했습니다.\n'
  exit 0
fi

deleted=0
for item in "${backup_items[@]}"; do
  item_name="${item##*/}"
  case "$item_name" in
    *.backup.*|backup.*)
      rm -rf -- "$item"
      deleted=$((deleted + 1))
      printf '삭제됨: %s\n' "$item"
      ;;
  esac
done

printf '총 %d개 백업 항목을 삭제했습니다.\n' "$deleted"
