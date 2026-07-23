#!/usr/bin/env bash

# vibe-frame-kit 통합 Bash 설치 스크립트
#
# Usage:
#   ./install.sh -t <gemini|claude|codex> -g <git_remote_url>
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

is_valid_git_url() {
  local value="$1"
  [[ -n "$value" && "$value" =~ ^(https://|git@|ssh://).+ ]]
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
    else
      sed -i "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$dest_file"
      sed -i "s|{{INSTALL_PATH}}|$INSTALL_PATH|g" "$dest_file"
      sed -i "s/{{CONFIG_FILE}}/$CONFIG_FILE/g" "$dest_file"
      sed -i "s/{{RULES_FILE}}/$RULES_FILE/g" "$dest_file"
      sed -i "s|{{GIT_REMOTE_URL}}|$GIT_URL|g" "$dest_file"
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


TOOL=""
GIT_URL=""

# 파라미터 처리 (-t <tool1,tool2>, -g <git_remote_url>)
while getopts "t:g:" opt; do
  case $opt in
    t) TOOL="$OPTARG" ;;
    g) GIT_URL="$OPTARG" ;;
    *) fail "잘못된 옵션입니다." ; exit 1 ;;
  esac
done

# 대화식 선택 루프 (체크박스형 복수 선택)
if [ -z "$TOOL" ]; then
  options=(
    "Gemini (Antigravity):gemini:false"
    "Claude (Desktop / Code CLI):claude:false"
    "Codex (Cursor 등):codex:false"
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

if [ -z "$GIT_URL" ]; then
  read -rp "프로젝트 Git 원격 저장소 주소를 입력하세요 (선택사항, 건너뛰려면 Enter): " GIT_URL
  GIT_URL=$(echo "$GIT_URL" | tr -d '\r')
  if [ -n "$GIT_URL" ] && ! is_valid_git_url "$GIT_URL"; then
    while true; do
      fail "유효하지 않은 Git 주소 형식입니다. 올바른 주소를 입력하거나 건너뛰려면 Enter를 누르세요."
      read -rp "프로젝트 Git 원격 저장소 주소를 입력하세요 (Optional): " GIT_URL
      GIT_URL=$(echo "$GIT_URL" | tr -d '\r')
      if [ -z "$GIT_URL" ] || is_valid_git_url "$GIT_URL"; then
        break
      fi
    done
  fi
elif ! is_valid_git_url "$GIT_URL"; then
  fail "유효한 Git 원격 저장소 주소 형식이 아닙니다. 지원 형식: https://..., git@..., ssh://..."
  exit 1
fi

# 프로젝트 폴더 설정 로직
SPECIFY_FOLDER=""
while [[ "$SPECIFY_FOLDER" != "Y" && "$SPECIFY_FOLDER" != "N" ]]; do
  read -rp "프로젝트 폴더를 지정하여 config.toml을 바로 배포하시겠습니까? (Y/N): " SPECIFY_FOLDER
  SPECIFY_FOLDER=$(echo "$SPECIFY_FOLDER" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
done

PROJ_FOLDER=""
PROJ_NAME=""
DEPLOY_CONFIG_DIRECTLY=false

if [ "$SPECIFY_FOLDER" = "Y" ]; then
  while [ -z "$PROJ_FOLDER" ]; do
    read -rp "프로젝트 폴더 경로를 입력하세요 (예: /workspace/my-project): " PROJ_FOLDER
    PROJ_FOLDER=$(echo "$PROJ_FOLDER" | tr -d '\r')
  done

  # 절대경로 획득
  if [[ "$PROJ_FOLDER" != /* ]]; then
    PROJ_FOLDER="$(pwd)/$PROJ_FOLDER"
  fi

  if [ ! -d "$PROJ_FOLDER" ]; then
    mkdir -p "$PROJ_FOLDER"
    success "프로젝트 폴더를 생성했습니다: $PROJ_FOLDER"
  fi

  DEFAULT_PROJ_NAME=$(basename "$PROJ_FOLDER")
  read -rp "프로젝트 이름을 입력하세요 [기본값: $DEFAULT_PROJ_NAME]: " PROJ_NAME
  PROJ_NAME=$(echo "$PROJ_NAME" | tr -d '\r')
  if [ -z "$PROJ_NAME" ]; then
    PROJ_NAME="$DEFAULT_PROJ_NAME"
  fi
  DEPLOY_CONFIG_DIRECTLY=true
  
  # Git remote URL과 프로젝트 폴더 동기화
  if [ -n "$GIT_URL" ]; then
    info "프로젝트 폴더와 Git 원격 저장소 동기화 중: $GIT_URL"
    if [ -d "$PROJ_FOLDER/.git" ]; then
      info "기존 Git 저장소가 존재합니다. 원격 저장소 URL을 업데이트합니다."
      git -C "$PROJ_FOLDER" remote set-url origin "$GIT_URL" 2>/dev/null || git -C "$PROJ_FOLDER" remote add origin "$GIT_URL" 2>/dev/null
      info "원격 저장소로부터 변경 사항을 가져오는 중..."
      git -C "$PROJ_FOLDER" fetch --all
    else
      if [ -z "$(ls -A "$PROJ_FOLDER")" ]; then
        info "폴더가 비어 있습니다. Git clone을 수행합니다..."
        git clone "$GIT_URL" "$PROJ_FOLDER" || fail "Git clone에 실패했습니다. 설정 파일 배포는 계속 진행합니다."
      else
        info "폴더가 비어 있지 않습니다. 로컬 Git 저장소를 초기화합니다..."
        git -C "$PROJ_FOLDER" init
        git -C "$PROJ_FOLDER" remote add origin "$GIT_URL" 2>/dev/null
        git -C "$PROJ_FOLDER" fetch origin
        success "Git 저장소를 초기화하고 원격을 추가했습니다."
      fi
    fi
  fi
fi

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
      fail "지원하지 않는 툴 유형입니다: $current_tool"
      exit 1
      ;;
  esac

  info "vibe-frame-kit ($AGENT_NAME 환경) 설치를 시작합니다."
  info "저장소 위치: $REPO_ROOT"
  info "설치 위치: $INSTALL_BASE_DIR"
  info "프로젝트 Git 원격 저장소 주소: $GIT_URL"
  mkdir -p "$INSTALL_BASE_DIR"

  SOURCE_COMMON_DIR="$REPO_ROOT/common"
  if [ ! -d "$SOURCE_COMMON_DIR" ]; then
    fail "공통 소스 폴더를 찾을 수 없습니다: $SOURCE_COMMON_DIR"
    exit 1
  fi

  # 기존 디렉토리 백업
  DIRECTORIES_TO_COPY=("agents" "skills" "config" "prompts" "templates" "docs" "study")
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

  # 기존 RULES.md 파일 백업
  TARGET_RULES_MD_FILE="$INSTALL_BASE_DIR/RULES.md"
  if [ -f "$TARGET_RULES_MD_FILE" ]; then
    BACKUP_RULES_MD_PATH="$INSTALL_BASE_DIR/RULES.md.backup.$TIMESTAMP"
    cp "$TARGET_RULES_MD_FILE" "$BACKUP_RULES_MD_PATH"
    success "기존 RULES.md 파일을 백업했습니다: $BACKUP_RULES_MD_PATH"
  fi

  # 복사 및 변수 치환 배포
  copy_and_replace_directory "$SOURCE_COMMON_DIR" "$INSTALL_BASE_DIR"
  success "프레임워크 코어 파일 배포 및 템플릿 치환이 완료되었습니다."

  # config.toml 파일 직접 배포
  if [ "$DEPLOY_CONFIG_DIRECTLY" = true ]; then
    SAMPLE_CONFIG_FILE="$SOURCE_COMMON_DIR/config/common.config.sample.toml"
    TARGET_CONFIG_PATH="$PROJ_FOLDER/config.toml"
    if [ -f "$SAMPLE_CONFIG_FILE" ]; then
      cp "$SAMPLE_CONFIG_FILE" "$TARGET_CONFIG_PATH"
      if command -v python3 &>/dev/null; then
        python3 -c "
try:
    with open('$TARGET_CONFIG_PATH', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    content = content.replace('name = \"my-ai-service-project\"', 'name = \"$PROJ_NAME\"')
    content = content.replace('{{AGENT_NAME}}', '$AGENT_NAME')
    content = content.replace('{{INSTALL_PATH}}', '$INSTALL_PATH')
    content = content.replace('{{CONFIG_FILE}}', 'config.toml')
    content = content.replace('{{RULES_FILE}}', '$RULES_FILE')
    content = content.replace('{{GIT_REMOTE_URL}}', '$GIT_URL')
    if not '$GIT_URL':
        content = content.replace('auto_commit_push = true', 'auto_commit_push = false')
    with open('$TARGET_CONFIG_PATH', 'w', encoding='utf-8') as f:
        f.write(content)
except Exception as e:
    import sys
    sys.exit(1)
"
      else
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "s/name = \"my-ai-service-project\"/name = \"$PROJ_NAME\"/g" "$TARGET_CONFIG_PATH"
          sed -i '' "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$TARGET_CONFIG_PATH"
          sed -i '' "s|{{INSTALL_PATH}}|$INSTALL_PATH|g" "$TARGET_CONFIG_PATH"
          sed -i '' "s/{{CONFIG_FILE}}/config.toml/g" "$TARGET_CONFIG_PATH"
          sed -i '' "s/{{RULES_FILE}}/$RULES_FILE/g" "$TARGET_CONFIG_PATH"
          sed -i '' "s|{{GIT_REMOTE_URL}}|$GIT_URL|g" "$TARGET_CONFIG_PATH"
          if [ -z "$GIT_URL" ]; then
            sed -i '' "s/auto_commit_push = true/auto_commit_push = false/g" "$TARGET_CONFIG_PATH"
          fi
        else
          sed -i "s/name = \"my-ai-service-project\"/name = \"$PROJ_NAME\"/g" "$TARGET_CONFIG_PATH"
          sed -i "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$TARGET_CONFIG_PATH"
          sed -i "s|{{INSTALL_PATH}}|$INSTALL_PATH|g" "$TARGET_CONFIG_PATH"
          sed -i "s/{{CONFIG_FILE}}/config.toml/g" "$TARGET_CONFIG_PATH"
          sed -i "s/{{RULES_FILE}}/$RULES_FILE/g" "$TARGET_CONFIG_PATH"
          sed -i "s|{{GIT_REMOTE_URL}}|$GIT_URL|g" "$TARGET_CONFIG_PATH"
          if [ -z "$GIT_URL" ]; then
            sed -i "s/auto_commit_push = true/auto_commit_push = false/g" "$TARGET_CONFIG_PATH"
          fi
        fi
      fi
      success "프로젝트 폴더 내에 config.toml을 자동 생성했습니다: $TARGET_CONFIG_PATH"
    else
      fail "샘플 설정 파일이 존재하지 않아 config.toml을 자동 생성하지 못했습니다."
    fi
  fi

  printf '\n'
  success "vibe-frame-kit ($AGENT_NAME 버전) 설치가 완료되었습니다."
  printf '\033[32m설치된 항목:\033[0m\n'
  printf -- '- %s/%s\n' "$INSTALL_PATH" "$RULES_FILE"
  printf -- '- %s/RULES.md\n' "$INSTALL_PATH"
  printf -- '- %s/agents/\n' "$INSTALL_PATH"
  printf -- '- %s/skills/\n' "$INSTALL_PATH"
  printf -- '- %s/config/\n' "$INSTALL_PATH"
  printf -- '- %s/prompts/\n' "$INSTALL_PATH"
  printf -- '- %s/templates/\n' "$INSTALL_PATH"
  printf -- '- %s/docs/\n' "$INSTALL_PATH"
  printf -- '- %s/study/\n' "$INSTALL_PATH"
  printf '\n'

  printf '\033[33m=============================================\033[0m\n'
  printf '\033[33m [Action Required: Setup Configuration]\033[0m\n'
  printf '\033[33m=============================================\033[0m\n'
  if [ "$DEPLOY_CONFIG_DIRECTLY" = true ]; then
    printf ' 1. Configuration file successfully created:\n'
    printf '    %s/config.toml\n' "$PROJ_FOLDER"
    printf ' 2. Status:\n'
    printf '    No further action needed! The Agent will now read settings from this file.\n'
  else
    printf ' 1. Sample TOML file location:\n'
    printf '    %s/config/%s\n' "$INSTALL_PATH" "$CONFIG_FILE"
    printf ' 2. How to activate:\n'
    printf '    - Copy the sample file above to your '\''Project Root Folder'\''\n'
    printf '    - Rename the file to '\''config.toml'\'' to apply settings to the Agent.\n'
    printf '      (e.g., %s -> config.toml)\n' "$CONFIG_FILE"
  fi
  printf ' 3. Git remote URL injected:\n'
  printf '    %s\n' "$GIT_URL"
  printf '\033[33m=============================================\033[0m\n'
  printf '\n'
done
