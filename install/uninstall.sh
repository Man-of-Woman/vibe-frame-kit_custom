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

# Scan installed tools
installed_tools=()
[ -f "$HOME/.gemini/config/RULES.md" ] && installed_tools+=("gemini")
[ -f "$HOME/.claude/RULES.md" ] && installed_tools+=("claude")
[ -f "$HOME/.codex/RULES.md" ] && installed_tools+=("codex")

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
    # 2개 이상인 경우 체크박스 토글
    selected_gemini=false
    selected_claude=false
    selected_codex=false
    
    # 헬퍼 체크
    has_gemini=false
    has_claude=false
    has_codex=false
    for t in "${installed_tools[@]}"; do
      [ "$t" = "gemini" ] && has_gemini=true
      [ "$t" = "claude" ] && has_claude=true
      [ "$t" = "codex" ] && has_codex=true
    done

    while true; do
      clear
      echo "============================================="
      echo " vibe-frame-kit 통합 제거를 시작합니다."
      echo "============================================="
      echo "제거할 AI 개발 툴 환경을 선택하세요 (복수 선택 가능):"
      echo " (번호를 입력하여 토글하고, 엔터를 누르면 확정됩니다. 예: 1 또는 1,2)"
      echo ""

      options_count=0
      gemini_opt_num=""
      claude_opt_num=""
      codex_opt_num=""

      if [ "$has_gemini" = true ]; then
        options_count=$((options_count+1))
        gemini_opt_num=$options_count
        check_gemini="[ ]"
        [ "$selected_gemini" = true ] && check_gemini="[X]"
        echo "  $check_gemini $gemini_opt_num) Gemini (Antigravity)"
      fi

      if [ "$has_claude" = true ]; then
        options_count=$((options_count+1))
        claude_opt_num=$options_count
        check_claude="[ ]"
        [ "$selected_claude" = true ] && check_claude="[X]"
        echo "  $check_claude $claude_opt_num) Claude (Desktop / Code CLI)"
      fi

      if [ "$has_codex" = true ]; then
        options_count=$((options_count+1))
        codex_opt_num=$options_count
        check_codex="[ ]"
        [ "$selected_codex" = true ] && check_codex="[X]"
        echo "  $check_codex $codex_opt_num) Codex (Cursor 등)"
      fi
      echo ""

      read -rp "선택 (1-$options_count, 확정하려면 Enter): " Choice
      Choice=$(echo "$Choice" | tr -d '\r')
      if [ -z "$Choice" ]; then
        if [ "$selected_gemini" = false ] && [ "$selected_claude" = false ] && [ "$selected_codex" = false ]; then
          fail "최소 하나의 제거 대상을 선택해야 합니다."
          sleep 1
          continue
        else
          break
        fi
      fi

      IFS=',' read -r -a choices_arr <<< "$Choice"
      for val in "${choices_arr[@]}"; do
        val=$(echo "$val" | tr -d '[:space:]')
        if [ "$val" = "$gemini_opt_num" ] && [ -n "$gemini_opt_num" ]; then
          [ "$selected_gemini" = true ] && selected_gemini=false || selected_gemini=true
        elif [ "$val" = "$claude_opt_num" ] && [ -n "$claude_opt_num" ]; then
          [ "$selected_claude" = true ] && selected_claude=false || selected_claude=true
        elif [ "$val" = "$codex_opt_num" ] && [ -n "$codex_opt_num" ]; then
          [ "$selected_codex" = true ] && selected_codex=false || selected_codex=true
        else
          fail "잘못된 입력입니다: $val"
          sleep 1
        fi
      done
    done

    [ "$selected_gemini" = true ] && TOOL="${TOOL:+$TOOL,}gemini"
    [ "$selected_claude" = true ] && TOOL="${TOOL:+$TOOL,}claude"
    [ "$selected_codex" = true ] && TOOL="${TOOL:+$TOOL,}codex"
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
