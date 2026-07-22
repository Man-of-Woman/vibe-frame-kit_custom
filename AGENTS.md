# Repository Guidelines

## 프로젝트 구조와 모듈 구성

이 저장소는 Gemini, Claude, Codex용 AI 개발 워크플로 패키지이며, 일반적인 `src/` 기반 애플리케이션이 아닙니다. 도구와 무관하게 공통으로 쓰는 자료는 `common/`에 둡니다.

- `common/skills/`: 작업 단계별 `SKILL.md` 정의
- `common/prompts/`, `common/templates/`, `common/study/`, `common/docs/`: 프롬프트, 산출물 양식, 학습 자료, 안내 문서
- `install/`: Windows PowerShell 및 macOS/Linux Bash 설치·제거 스크립트
- `walkthrough/`: `YYYYMMDD_NN_간단한_설명.md` 형식의 작업 기록
- `config.toml`: 루트 샘플 설정 파일. 인증 정보는 절대 작성하지 않습니다.

## 빌드, 테스트, 개발 명령

별도 빌드 과정이나 패키지 기반 자동 테스트는 없습니다. 설치 스크립트를 변경하면 임시 프로젝트 폴더에서 설치와 제거를 직접 확인합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\install\install.ps1 -Tool codex
powershell -ExecutionPolicy Bypass -File .\install\uninstall.ps1 -Tool codex
```

macOS/Linux에서는 먼저 `chmod +x install/install.sh install/uninstall.sh`를 실행한 뒤, `./install/install.sh -t codex` 및 `./install/uninstall.sh -t codex`를 사용합니다. 에이전트 파일, 스킬, 프롬프트, 설정이 설치되며 제거 시 관리 대상 파일만 삭제되는지 확인합니다.

## 코드 스타일과 이름 규칙

기존 파일의 형식을 우선 따릅니다. PowerShell은 네 칸 들여쓰기, PascalCase 함수명(예: `Safe-CopyAndReplaceDirectory`), 매개변수 검증을 사용합니다. Bash는 두 칸 들여쓰기, 소문자 `snake_case` 함수명, 변수 인용, `set -euo pipefail`을 사용합니다. Markdown 경로는 저장소 루트 기준으로 표기하고, 새 스킬은 kebab-case 폴더 아래 `SKILL.md`로 만듭니다.

## 테스트 지침

설치 스크립트를 수정할 때마다 해당 운영체제에서 최소 한 개 도구의 설치와 제거를 확인합니다. 검증 로직을 바꾸면 잘못된 도구명과 Git URL도 확인합니다. 실행한 수동 검증 절차와 결과를 PR에 기록하며, 실행 가능한 테스트 체계가 도입되기 전에는 자동 테스트 완료로 표현하지 않습니다.

## 커밋과 Pull Request 지침

최근 이력은 간결한 한글 요약과 `feat:`, `fix:`, `docs:`, `chore:` 같은 접두사를 함께 사용합니다. 커밋은 한 가지 목적에 집중합니다. 예: `fix: PowerShell 설치 경로 처리 수정`. PR에는 영향받는 도구, 설치·제거 검증 결과, 설정 마이그레이션 여부를 적고, 동작 변화가 보이면 화면 또는 터미널 결과를 첨부합니다. `.env`, 토큰, 로컬 백업 파일은 커밋하지 않습니다.

## 1. 작업 완료 보고서 (Walkthrough) 작성 규칙

에이전트는 작업이 완료될 때마다 다음 규칙에 따라 작업 완료 보고서를 저장해야 합니다.

1. **저장 위치**: 프로젝트 루트의 `walkthrough/` 폴더 내에 저장합니다.
2. **파일명 규칙**: `YYYYMMDD_순번_커밋메시지.md` 형식으로 파일을 생성합니다.
   * 예시: `20260721_01_add_claude_framework.md`
3. **순번 적용 규칙**: 동일한 날짜에 작성되는 보고서의 순번은 `01`번부터 시작하여 `99`번까지 순차적으로 누적하여 적용합니다.
4. **저장 전 승인 절차 (중요)**: 
   * 작업을 마친 후 완료 보고서를 저장하기 전에, **사용자에게 보고서를 저장할지 먼저 묻고 승인을 요청**해야 합니다.
   * 사용자가 승인(예: "승인", "저장해줘" 등)하면 `walkthrough/` 폴더에 해당 보고서 파일을 추가합니다.
5. **본문 서식 규칙 (중요)**: 
   * 작업 완료 보고서의 맨 상단에는 **사용자가 전달한 작업 지시사항 원문을 그대로 인용**하여 추가합니다.
   * 작업 지시사항 원문 인용 바로 아래에는 **작업을 수행할 때 사용한 AI 모델명(예: Gemini 3.5 Flash (Medium) 등)**을 명시적으로 기록합니다.
   * AI 모델명 하단에는 **해당 대화 세션을 수행하며 도구가 기록한 작업 수행 시간(초) 및 소모한 대략적인 토큰양(토큰 수)**을 확인하여 가능한 한 함께 기록합니다.

---

## 2. 기본 개발 및 협업 지침

* 사용자의 명시적인 승인 없이 중요 아키텍처나 설정을 임의로 변경하지 않습니다.
* 모든 변경 사항은 점진적으로 설계 및 구현하며, 구현이 완료되면 반드시 직접적인 확인/검증 방법 및 실행 명령어를 제공합니다.
* 보안 원칙에 따라 API Key, 토큰 및 비밀번호 등의 민감한 크레덴셜 정보가 코드나 파일에 노출되지 않도록 철저히 관리합니다.
* **커밋 메시지 규칙 (중요)**: Git 커밋 메시지는 항상 한글을 기반으로 작성합니다.
