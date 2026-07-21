# vibe-frame-kit

`vibe-frame-kit`은 재직자 AI 서비스 개발 과정 수강생들이 다양한 AI 개발 툴을 활용하여 프로젝트를 점진적이고 구조적으로 진행할 수 있도록 돕는 공통 Vibe Frame Kit 프레임워크입니다.

이 저장소는 특정 AI 서비스의 완성 코드를 제공하기보다, 어떤 프로젝트를 만들든 공통으로 적용할 수 있는 개발 흐름, 프롬프트, 템플릿, 규칙, 제한 사항을 제공하는 것을 목표로 합니다.

---

## 1. 대상 개발 툴 및 배포 프레임워크

프로젝트 폴더 구조는 대상 개발 툴의 특성과 기능 지원 범위에 맞춰 최적화되어 분류되어 있습니다.

| 폴더명 | 대상 개발 툴 | 특징 | 설치 경로 |
| --- | --- | --- | --- |
| **`for_codex`** | **Codex (Cursor 등)** | 일반적이고 심플한 기능 구현 프롬프트 제공 (10개 스킬) | `~/.codex` |
| **`for_gemini`** | **Antigravity (Google Gemini)** | 강력한 에이전트 환경 및 Context Map, Agile 백로그 등을 포함한 설계 중심 프롬프트 제공 (14개 스킬) | `~/.gemini/config` |
| **`for_claude`** | **Claude (Desktop / Code CLI)** | Claude Code CLI의 자동 지시사항 연동 규격(`CLAUDE.md`)을 지원하는 에이전트용 프레임워크 (14개 스킬) | `~/.claude` |

---

## 2. 제공 기능 및 개발 프로세스

모든 프레임워크는 수강생이 아래의 체계적인 개발 흐름을 따르도록 설계되어 있습니다.

```text
요구사항 정의
→ 기능 분해
→ MVP 설계
→ 프로젝트 구조 생성
→ 기능 구현 (설계 & 도메인 모델링)
→ 오류 분석 및 디버깅
→ 테스트 시나리오 검증 및 자동화 테스트
→ 리팩토링
→ README / 보고서 작성
```

---

## 3. 설치 및 제거 방법

각 개발 툴 폴더 내의 `scripts/` 디렉토리에 사용자 컴퓨터 환경에 맞는 설치(`install`) 및 제거(`uninstall`) 스크립트가 제공됩니다.

### 1) Codex 프레임워크 설치/제거
* **Windows (PowerShell)**:
  ```powershell
  # 설치
  powershell -ExecutionPolicy Bypass -File .\for_codex\scripts\install.ps1
  # 제거
  powershell -ExecutionPolicy Bypass -File .\for_codex\scripts\uninstall.ps1
  ```
* **macOS / Linux (Bash)**:
  ```bash
  # 설치
  chmod +x for_codex/scripts/install.sh && ./for_codex/scripts/install.sh
  # 제거
  chmod +x for_codex/scripts/uninstall.sh && ./for_codex/scripts/uninstall.sh
  ```

### 2) Gemini 프레임워크 설치/제거
* **Windows (PowerShell)**:
  ```powershell
  # 설치
  powershell -ExecutionPolicy Bypass -File .\for_gemini\scripts\install.ps1
  # 제거
  powershell -ExecutionPolicy Bypass -File .\for_gemini\scripts\uninstall.ps1
  ```
* **macOS / Linux (Bash)**:
  ```bash
  # 설치
  chmod +x for_gemini/scripts/install.sh && ./for_gemini/scripts/install.sh
  # 제거
  chmod +x for_gemini/scripts/uninstall.sh && ./for_gemini/scripts/uninstall.sh
  ```

### 3) Claude 프레임워크 설치/제거
* **Windows (PowerShell)**:
  ```powershell
  # 설치
  powershell -ExecutionPolicy Bypass -File .\for_claude\scripts\install.ps1
  # 제거
  powershell -ExecutionPolicy Bypass -File .\for_claude\scripts\uninstall.ps1
  ```
* **macOS / Linux (Bash)**:
  ```bash
  # 설치
  chmod +x for_claude/scripts/install.sh && ./for_claude/scripts/install.sh
  # 제거
  chmod +x for_claude/scripts/uninstall.sh && ./for_claude/scripts/uninstall.sh
  ```

---

## 4. 저장소 상세 구조 안내

각 배포판은 툴의 성능과 컨텍스트 제한을 고려해 커스터마이징되어 있습니다.
- **`agents/`**: 에이전트 라우팅 및 역할별 매핑 파일 (`routing.md`)
- **`skills/`**: 요구사항 정의, MVP 설계, 디버깅 등 핵심 작업을 가이드하는 AI 스킬 파일 목록
- **`prompts/`**: 수강생이 복사하여 AI 개발 툴에 붙여넣을 수 있는 단계별 한글 프롬프트
- **`templates/`**: 산출물(요구사항 정의서, MVP 계획서, 테스트 시나리오 등)의 마크다운 템플릿
- **`config/`**: 스킬 정의 텍스트 및 환경 설정 파일 샘플 (`*.config.sample.toml`)
- **`docs/`**: 수강생 가이드, 강사 가이드, 보안 체크리스트, 자가 설치 테스트 절차서

---

## 5. 보안 수칙

AI 서비스 개발 실습 중 API 키, 인증 토큰 등의 유출을 차단하기 위한 기본 보안 규칙입니다.
- `.env` 파일은 절대로 Git 저장소에 커밋하지 마세요. (각 프레임워크는 `.gitignore`를 통해 자동 배제합니다)
- `.env.example` 파일에는 가짜 더미 키값만 기재하세요.
- AI 개발 툴과의 대화창에 실제 인증 정보나 비밀번호를 직접 입력하지 않도록 유의하세요.
- 배포 및 프로젝트 제출 전 `security-checker` 스킬을 사용하여 민감한 크레덴셜이 노출되지 않았는지 자체 점검을 수행하는 것을 강력히 권장합니다.
