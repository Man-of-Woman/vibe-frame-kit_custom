#!/usr/bin/env bash

# vibe-frame-kit 통합 Bash 설치 스크립트
#
# Usage:
#   ./install.sh -t <gemini|claude|codex|muse|opencode>
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
        ('{{RULES_FILE}}', '$RULES_FILE'),
        ('{{GIT_REMOTE_URL}}', '$GIT_URL')
    ]:
        content = content.replace(k, v)
    if not '$GIT_URL':
        content = content.replace('auto_commit_push = true', 'auto_commit_push = false')
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
      sed -i '' "s|{{GIT_REMOTE_URL}}|$GIT_URL|g" "$dest_file"
      if [ -z "$GIT_URL" ]; then
        sed -i '' "s/auto_commit_push = true/auto_commit_push = false/g" "$dest_file"
      fi
    else
      sed -i "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$dest_file"
      sed -i "s|{{INSTALL_PATH}}|$INSTALL_PATH|g" "$dest_file"
      sed -i "s/{{CONFIG_FILE}}/$CONFIG_FILE/g" "$dest_file"
      sed -i "s/{{RULES_FILE}}/$RULES_FILE/g" "$dest_file"
      sed -i "s|{{GIT_REMOTE_URL}}|$GIT_URL|g" "$dest_file"
      if [ -z "$GIT_URL" ]; then
        sed -i "s/auto_commit_push = true/auto_commit_push = false/g" "$dest_file"
      fi
    fi
  fi
}

# 재귀 복사 및 치환 배포 함수
copy_and_replace_directory() {
  local src_dir="$1"
  local dest_dir="$2"
  local exclude_skills="${3:-false}"
  
  mkdir -p "$dest_dir"
  
  # 모든 하위 파일 및 폴더를 탐색
  find "$src_dir" -mindepth 1 | while read -r item; do
    local rel_path="${item#$src_dir/}"
    local dest_item="$dest_dir/$rel_path"
    if [ "$exclude_skills" = true ] && { [ "$rel_path" = "skills" ] || [[ "$rel_path" == skills/* ]]; }; then
      continue
    fi
    
    # AGENTS.md ➡️ RULES_FILE 명칭 변경
    if [ "$rel_path" = "AGENTS.md" ]; then
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

deploy_ignore_files() {
  local repo_root="$1"
  
  local agent_ignore_content
  agent_ignore_content="# vibe-frame-kit ignore rules (AI Agent indexing)
*.backup.*
backup.*
venv/
.venv/
node_modules/
.git/
common/
install/
walkthrough/
study/"

  local git_ignore_content
  git_ignore_content="# vibe-frame-kit ignore rules (Git version control)
*.backup.*
backup.*
venv/
.venv/
node_modules/
.env
.env.local
.env.*.local"

  local agent_files=(".cursorignore" ".geminiignore")
  for file in "${agent_files[@]}"; do
    local file_path="$repo_root/$file"
    if [ ! -f "$file_path" ]; then
      echo "$agent_ignore_content" > "$file_path"
      success "Created $file at repository root to prevent token waste."
    fi
  done

  local git_ignore_path="$repo_root/.gitignore"
  if [ ! -f "$git_ignore_path" ]; then
    echo "$git_ignore_content" > "$git_ignore_path"
    success "Created .gitignore at repository root to secure credentials."
  fi
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
    echo " vibe-frame-kit 통합 설치를 시작합니다."
    echo "============================================="
    echo "설치할 AI 개발 툴 환경을 선택하세요 (복수 선택 가능):"
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

    # read key input (read 실패/EOF·타임아웃은 메뉴 루프 보호를 위해 무시)
    read -rsn1 key || true
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key || true
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


TOOL=""
# Git remote URL은 설치 시 지정하지 않는다. 필요하면 프로젝트의 config.toml에서 직접 설정한다.
GIT_URL=""

# 파라미터 처리 (-t <tool1,tool2>)
while getopts "t:" opt; do
  case $opt in
    t) TOOL="$OPTARG" ;;
    *) fail "잘못된 옵션입니다." ; exit 1 ;;
  esac
done

# 대화식 선택 루프 (체크박스형 복수 선택)
if [ -z "$TOOL" ]; then
  options=(
    "Gemini (Antigravity):gemini:false"
    "Claude (Desktop / Code CLI):claude:false"
    "Codex (Cursor 등):codex:false"
    "Muse (Muse Spark / Muse Code CLI):muse:false"
    "OpenCode:opencode:false"
  )
  while true; do
    TOOL=$(show_multi_select_menu "설치할 AI 개발 툴 환경을 선택하세요 (복수 선택 가능)" "${options[@]}")
    if [ -n "$TOOL" ]; then
      break
    else
      fail "최소 하나의 툴을 선택해야 합니다."
      sleep 1
    fi
  done
fi

IFS=',' read -r -a selected_tools_arr <<< "$TOOL"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

# deploy ignore files at repository root once
deploy_ignore_files "$REPO_ROOT"

for current_tool in "${selected_tools_arr[@]}"; do
  current_tool=$(echo "$current_tool" | tr -d '[:space:]')
  # 변수 테이블 바인딩
  case "$current_tool" in
    gemini)
      INSTALL_BASE_DIR="$HOME/.gemini/config"
      SKILL_INSTALL_DIR="$INSTALL_BASE_DIR/skills"
      AGENT_NAME="Gemini"
      INSTALL_PATH="~/.gemini/config"
      CONFIG_FILE="gemini.config.sample.toml"
      RULES_FILE="AGENTS.md"
      ;;
    claude)
      INSTALL_BASE_DIR="$HOME/.claude"
      SKILL_INSTALL_DIR="$INSTALL_BASE_DIR/skills"
      AGENT_NAME="Claude"
      INSTALL_PATH="~/.claude"
      CONFIG_FILE="claude.config.sample.toml"
      RULES_FILE="CLAUDE.md"
      ;;
    codex)
      INSTALL_BASE_DIR="$HOME/.codex"
      SKILL_INSTALL_DIR="$HOME/.agents/skills"
      AGENT_NAME="Codex"
      INSTALL_PATH="~/.codex"
      CONFIG_FILE="codex.config.sample.toml"
      RULES_FILE="AGENTS.md"
      ;;
    muse)
      INSTALL_BASE_DIR="$HOME/.config/muse"
      SKILL_INSTALL_DIR="$INSTALL_BASE_DIR/skills"
      AGENT_NAME="Muse"
      INSTALL_PATH="~/.config/muse"
      CONFIG_FILE="muse.config.sample.toml"
      RULES_FILE="AGENTS.md"
      ;;
    opencode)
      INSTALL_BASE_DIR="$HOME/.config/opencode"
      SKILL_INSTALL_DIR="$INSTALL_BASE_DIR/skills"
      AGENT_NAME="OpenCode"
      INSTALL_PATH="~/.config/opencode"
      CONFIG_FILE="opencode.config.sample.toml"
      RULES_FILE="AGENTS.md"
      ;;
    *)
      fail "지원하지 않는 툴 유형입니다: $current_tool"
      exit 1
      ;;
  esac

  info "vibe-frame-kit ($AGENT_NAME 환경) 설치를 시작합니다."
  info "저장소 위치: $REPO_ROOT"
  info "설치 위치: $INSTALL_BASE_DIR"
  mkdir -p "$INSTALL_BASE_DIR"

  SOURCE_COMMON_DIR="$REPO_ROOT/common"
  if [ ! -d "$SOURCE_COMMON_DIR" ]; then
    fail "공통 소스 폴더를 찾을 수 없습니다: $SOURCE_COMMON_DIR"
    exit 1
  fi

  SOURCE_WALKTHROUGH_SKILL="$SOURCE_COMMON_DIR/skills/walkthrough/SKILL.md"
  if [ ! -f "$SOURCE_WALKTHROUGH_SKILL" ]; then
    fail "필수 walkthrough 스킬을 찾을 수 없습니다: $SOURCE_WALKTHROUGH_SKILL"
    exit 1
  fi

  # 기존 디렉토리 백업
  DIRECTORIES_TO_COPY=("agents" "config" "prompts" "templates" "docs" "study")
  for dir_name in "${DIRECTORIES_TO_COPY[@]}"; do
    target_dir="$INSTALL_BASE_DIR/$dir_name"
    if [ -d "$target_dir" ]; then
      BACKUP_DIR="$INSTALL_BASE_DIR/${dir_name}.backup.$TIMESTAMP"
      cp -R "$target_dir" "$BACKUP_DIR"
      success "기존 $dir_name 폴더를 백업했습니다: $BACKUP_DIR"
    fi
  done

  if [ -d "$SKILL_INSTALL_DIR" ]; then
    SKILL_BACKUP_DIR="$SKILL_INSTALL_DIR.backup.$TIMESTAMP"
    cp -R "$SKILL_INSTALL_DIR" "$SKILL_BACKUP_DIR"
    success "기존 skills 폴더를 백업했습니다: $SKILL_BACKUP_DIR"
  fi

  # 기존 규칙 파일 백업
  TARGET_RULES_FILE="$INSTALL_BASE_DIR/$RULES_FILE"
  if [ -f "$TARGET_RULES_FILE" ]; then
    BACKUP_RULES_PATH="$INSTALL_BASE_DIR/${RULES_FILE}.backup.$TIMESTAMP"
    cp "$TARGET_RULES_FILE" "$BACKUP_RULES_PATH"
    success "기존 $RULES_FILE 파일을 백업했습니다: $BACKUP_RULES_PATH"
  fi

  # 기존 RULES.md는 주 규칙 파일에 병합되었으므로 백업 후 제거
  TARGET_RULES_MD_FILE="$INSTALL_BASE_DIR/RULES.md"
  if [ -f "$TARGET_RULES_MD_FILE" ]; then
    BACKUP_RULES_MD_PATH="$INSTALL_BASE_DIR/RULES.md.backup.$TIMESTAMP"
    cp "$TARGET_RULES_MD_FILE" "$BACKUP_RULES_MD_PATH"
    rm -f "$TARGET_RULES_MD_FILE"
    success "기존 RULES.md 파일을 통합 규칙으로 마이그레이션했습니다: $BACKUP_RULES_MD_PATH"
  fi

  # 복사 및 변수 치환 배포
  copy_and_replace_directory "$SOURCE_COMMON_DIR" "$INSTALL_BASE_DIR" true
  copy_and_replace_directory "$SOURCE_COMMON_DIR/skills" "$SKILL_INSTALL_DIR"
  success "프레임워크 코어 파일 배포 및 템플릿 치환이 완료되었습니다."

  INSTALLED_WALKTHROUGH_SKILL="$SKILL_INSTALL_DIR/walkthrough/SKILL.md"
  if [ ! -f "$INSTALLED_WALKTHROUGH_SKILL" ]; then
    fail "walkthrough 스킬 설치 검증에 실패했습니다: $INSTALLED_WALKTHROUGH_SKILL"
    exit 1
  fi
  success "walkthrough 스킬 설치를 확인했습니다: $INSTALLED_WALKTHROUGH_SKILL"

  # Muse (Muse Code CLI): settings.json 보장 (schema_version=1, 기존 MCP 설정은 덮어쓰지 않음)
  if [ "$current_tool" = "muse" ]; then
    muse_settings_path="$INSTALL_BASE_DIR/settings.json"
    if [ ! -f "$muse_settings_path" ]; then
      printf '{ "schema_version": 1 }\n' > "$muse_settings_path"
      success "Muse settings.json을 생성했습니다 (schema_version 1)."
    else
      info "Muse settings.json이 이미 존재합니다. 그대로 유지합니다 (schema_version 1 필요)."
    fi
  fi

  printf '\n'
  success "vibe-frame-kit ($AGENT_NAME 버전) 설치가 완료되었습니다."
  printf '\033[32m설치된 항목:\033[0m\n'
  printf -- '- %s/%s\n' "$INSTALL_PATH" "$RULES_FILE"
  printf -- '- %s/agents/\n' "$INSTALL_PATH"
  printf -- '- %s\n' "$SKILL_INSTALL_DIR"
  printf -- '  - %s\n' "$INSTALLED_WALKTHROUGH_SKILL"
  printf -- '- %s/config/\n' "$INSTALL_PATH"
  printf -- '- %s/prompts/\n' "$INSTALL_PATH"
  printf -- '- %s/templates/\n' "$INSTALL_PATH"
  printf -- '- %s/docs/\n' "$INSTALL_PATH"
  printf -- '- %s/study/\n' "$INSTALL_PATH"
  printf '\n'

  printf '\033[33m=============================================\033[0m\n'
  printf '\033[33m [Action Required: Setup Configuration]\033[0m\n'
  printf '\033[33m=============================================\033[0m\n'
  printf ' 1. Sample TOML file location:\n'
  printf '    %s/config/%s\n' "$INSTALL_PATH" "$CONFIG_FILE"
  printf ' 2. How to activate:\n'
  printf '    - Copy the sample file above to your '\''Project Root Folder'\''\n'
  printf '    - Rename the file to '\''config.toml'\'' to apply settings to the Agent.\n'
  printf '      (e.g., %s -> config.toml)\n' "$CONFIG_FILE"
  printf '    - Fill in remote_repository_url and set auto_commit_push in your project config.toml manually.\n'
  printf '\033[33m=============================================\033[0m\n'
  printf '\n'
done
