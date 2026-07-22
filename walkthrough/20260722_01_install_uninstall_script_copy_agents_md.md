# 작업 완료 보고서

> **작업 지시사항 원문**
> install 스크립트를 수정하여 아래 목적에 부합하게 작동되도록 하고, 수정 후에는 테스트하라.
> uninstall 스크립트도 수정하라.
> 
> ./common/AGENTS.md 파일은 윈도우 codex의 경우 "$HOME/.codex/AGENTS.md" 로 복사하여야 한다.
> 마찬가지로 claude와 gemini도 동일한 기능을 할 수 있도록 배치해야 한다.

* **사용한 AI 모델**: Gemini 3.5 Flash (Medium)
* **작업 수행 시간**: 약 2080초
* **소모 토큰 수**: 약 75,000 토큰 (추정치)

---

## 1. 작업 개요
통합 설치(`install.ps1`, `install.sh`) 및 제거(`uninstall.ps1`, `uninstall.sh`) 스크립트의 작동 방식을 변경하여, `./common/AGENTS.md` 파일이 대상 환경(Codex, Gemini, Claude)에 대응하는 에이전트 전용 규칙 파일(`AGENTS.md` 또는 `CLAUDE.md`)로 정상적으로 복사되고 템플릿 변수가 치환되도록 개선했습니다. 또한 기존 `common/RULES.md` 파일은 `RULES.md`라는 고유 명칭으로 중복 충돌 없이 정상 복사 및 설치되도록 동기화했습니다.

---

## 2. 주요 변경 사항 및 작업 결과

### 1) `common/AGENTS.md` 템플릿화
* `common/AGENTS.md` 내부의 고정된 `"Codex"` 명칭을 템플릿 변수인 `{{AGENT_NAME}}`으로 변경하여 설치 툴에 따라 동적으로 치환될 수 있도록 지원했습니다.

### 2) 설치 스크립트 수정 (`install/install.ps1`, `install/install.sh`)
* 파일 복사 및 치환 시 규칙 파일로 명칭이 변경되는 소스 대상을 기존 `RULES.md`에서 `AGENTS.md`로 변경했습니다.
  * **Codex**: `common/AGENTS.md` ➡️ `$HOME/.codex/AGENTS.md` (`RULES_FILE`)
  * **Gemini**: `common/AGENTS.md` ➡️ `$HOME/.gemini/config/AGENTS.md` (`RULES_FILE`)
  * **Claude**: `common/AGENTS.md` ➡️ `$HOME/.claude/CLAUDE.md` (`RULES_FILE`)
* 기존 `common/RULES.md` 파일은 `RULES.md`라는 원래 이름 그대로 대상 폴더에 설치되도록 변경하여 두 규칙 파일이 충돌 없이 동시 설치되게 했습니다.
* 설치 전 백업 로직을 갱신하여 대상 폴더에 기존 `RULES.md`가 존재할 시 백업 파일(`RULES.md.backup.<Timestamp>`)을 생성하도록 보완했습니다.

### 3) 제거 스크립트 수정 (`install/uninstall.ps1`, `install/uninstall.sh`)
* 프레임워크가 제거될 때 대상 경로의 `RULES.md` 파일도 확실하게 함께 지워지도록 삭제 대상 파일 목록(`$TargetItems`/`TARGET_ITEMS`)에 `RULES.md`를 명시적으로 추가했습니다.

### 4) Git 상태 정리
* 대소문자 혼선으로 인해 Windows에서 트래킹 에러가 발생하던 루트의 `AGENT.md`(삭제됨)와 `AGENTS.md`(신규 생성) 변경 사항을 Git 스테이징(`git add .`)하여 형상 관리를 동기화했습니다.

---

## 3. 검증 결과
PowerShell 및 WSL Bash 환경에서 설치 및 제거 스크립트를 툴별(Codex, Gemini, Claude)로 순차 실행하여 정상 작동 여부를 검증했습니다.

* **PowerShell 검증**:
  * `install.ps1 -Tool codex`: `~/.codex/AGENTS.md` 및 `~/.codex/RULES.md` 생성 성공 및 `Codex` 변수 치환 완료 확인.
  * `install.ps1 -Tool gemini`: `~/.gemini/config/AGENTS.md` 및 `~/.gemini/config/RULES.md` 생성 성공 및 `Gemini` 변수 치환 완료 확인.
  * `install.ps1 -Tool claude`: `~/.claude/CLAUDE.md` 및 `~/.claude/RULES.md` 생성 성공 및 `Claude` 변수 치환 완료 확인.
  * `uninstall.ps1`: 지정 툴의 프레임워크 폴더 및 `AGENTS.md`, `RULES.md`가 깔끔하게 삭제됨을 최종 확인.
* **WSL Bash 검증**:
  * `install.sh -t codex`: `/home/gharam/.codex/AGENTS.md` 및 `/home/gharam/.codex/RULES.md` 생성 성공 및 `Codex` 변수 치환 확인.
  * `uninstall.sh -t codex`: 설치된 모든 프레임워크 파일 및 규칙 문서가 완전히 삭제됨을 최종 확인.
