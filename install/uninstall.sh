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

show_multi_select_menu() {
  local title="$1"
  shift
  local options=("$@")
  local selected_index=0
  local num_options=${#options[@]}
  local done=false

  # Hide cursor
  printf '\033[?25l'
  trap 'printf "\033[?25h"' EXIT

  while [ "$done" = false ]; do
    clear
    echo "============================================="
    echo " vibe-frame-kit 통합 제거를 시작합니다."
    echo "============================================="
    echo "제거할 AI 개발 툴 환경을 선택하세요 (복수 선택 가능):"
    echo " (방향키 위/아래로 이동, 스페이스바로 선택 토글, 엔터로 확정)"
    echo ""

    for ((i=0; i<num_options; i++)); do
      IFS=':' read -r name value selected <<< "${options[i]}"
      check="[ ]"
      [ "$selected" = "true" ] && check="[X]"
      
      indicator=" "
      [ $i -eq $selected_index ] && indicator=">"

      color="\033[36m" # Cyan
      [ "$selected" = "true" ] && color="\033[32m" # Green
      [ $i -eq $selected_index ] && color="\033[37m" # White

      printf "  %s %s \033[1m%b%s\033[0m\n" "$indicator" "$check" "$color" "$name"
    done
    printf "\n"

    # read key input
    read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key
      if [[ "$key" == "[A" ]]; then # Up
        selected_index=$(( (selected_index - 1 + num_options) % num_options ))
      elif [[ "$key" == "[B" ]]; then # Down
        selected_index=$(( (selected_index + 1) % num_options ))
      fi
    elif [[ "$key" == "" ]]; then # Enter
      done=true
    elif [[ "$key" == " " ]]; then # Spacebar
      IFS=':' read -r name value selected <<< "${options[selected_index]}"
      if [ "$selected" = "true" ]; then
        selected="false"
      else
        selected="true"
      fi
      options[selected_index]="$name:$value:$selected"
    fi
  done

  printf '\033[?25h'
  trap - EXIT

  local results=""
  for ((i=0; i<num_options; i++)); do
    IFS=':' read -r name value selected <<< "${options[i]}"
    if [ "$selected" = "true" ]; then
      results="${results:+$results,}$value"
    fi
  done
  echo "$results"
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

# Scan installed tools
installed_tools=()
[ -f "$HOME/.gemini/config/AGENTS.md" ] && installed_tools+=("gemini")
[ -f "$HOME/.claude/CLAUDE.md" ] && installed_tools+=("claude")
[ -f "$HOME/.codex/AGENTS.md" ] && installed_tools+=("codex")

if [ -z "$TOOL" ]; then
  if [ ${#installed_tools[@]} -eq 0 ]; then
    success "설치된 vibe-frame-kit이 없습니다. 제거할 항목이 없습니다."
    exit 0
  elif [ ${#installed_tools[@]} -eq 1 ]; then
    single_tool="${installed_tools[0]}"
    read -rp "vibe-frame-kit이 [$single_tool]에 설치되어 있습니다. 제거하시겠습니까? (Y/N): " Confirm
    Confirm=$(echo "$Confirm" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    if [ "$Confirm" = "Y" ]; then
      TOOL="$single_tool"
    else
      info "제거를 취소했습니다."
      exit 0
    fi
  else
    options=()
    for t in "${installed_tools[@]}"; do
      case "$t" in
        gemini) options+=("Gemini (Antigravity):gemini:false") ;;
        claude) options+=("Claude (Desktop / Code CLI):claude:false") ;;
        codex) options+=("Codex (Cursor 등):codex:false") ;;
      esac
    done

    while true; do
      TOOL=$(show_multi_select_menu "제거할 AI 개발 툴 환경을 선택하세요 (복수 선택 가능)" "${options[@]}")
      if [ -n "$TOOL" ]; then
        break
      else
        fail "최소 하나의 제거 대상을 선택해야 합니다."
        sleep 1
      fi
    done
  fi
fi

IFS=',' read -r -a selected_tools_arr <<< "$TOOL"

for current_tool in "${selected_tools_arr[@]}"; do
  current_tool=$(echo "$current_tool" | tr -d '[:space:]')
  # 변수 테이블 바인딩
  case "$current_tool" in
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
      fail "지원하지 않는 툴 유형입니다: $current_tool"
      exit 1
      ;;
  esac

  info "vibe-frame-kit ($current_tool 버전) 제거를 시작합니다."
  info "대상 위치: $INSTALL_BASE_DIR"

  if [ ! -d "$INSTALL_BASE_DIR" ]; then
    success "제거 대상 폴더가 존재하지 않아 삭제할 항목이 없습니다."
    continue
  fi

  # 삭제할 파일 및 폴더 목록
  TARGET_ITEMS=(
    "$RULES_FILE"
    # 이전 버전에서 설치한 통합 전 RULES.md도 함께 정리합니다.
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
    if [ -z "$(ls -A "$INSTALL_BASE_DIR" || true)" ]; then
      rmdir "$INSTALL_BASE_DIR"
      success "비어 있는 $INSTALL_BASE_DIR 폴더를 제거했습니다."
    fi
  else
    info "$INSTALL_BASE_DIR 폴더에 백업 또는 개인용 다른 파일이 남아있어 폴더를 유지합니다."
  fi

  printf '\n'
  success "vibe-frame-kit ($current_tool 버전) 제거가 완료되었습니다."
  printf '\n'
done
