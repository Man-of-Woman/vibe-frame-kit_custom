# vibe-frame-kit

`vibe-frame-kit`은 재직자 AI 서비스 개발 과정 수강생들이 다양한 AI 개발 툴(Antigravity/Gemini, Claude, Codex/Cursor 등)을 활용하여 프로젝트를 점진적이고 구조적으로 진행할 수 있도록 돕는 공통 Vibe Frame Kit 프레임워크입니다.

이 저장소는 특정 AI 서비스의 완성 코드를 제공하기보다, 어떤 프로젝트를 만들든 공통으로 적용할 수 있는 개발 흐름, 프롬프트, 템플릿, 규칙, 제한 사항을 제공하는 것을 목표로 합니다.

---

## 1. Kit 소개 및 사용 대상

### 1) Kit 소개
AI 서비스 프로젝트는 아이디어만으로 바로 구현을 시작하면 요구사항이 불명확해지고, 기능 범위가 무분별하게 커지며, 오류 분석과 테스트가 뒤로 밀려 프로젝트가 중단되거나 지연되기 쉽습니다.
이 Kit는 AI 개발 에이전트와 페어 프로그래밍을 진행할 때 다음과 같은 공통 동작 기준을 제공하여 체계적인 개발을 유도합니다.

* **요구사항 정의 우선**: 개발 전 아이디어를 구조화하고 명확한 범위를 정의합니다.
* **기능 분해와 MVP 지향**: 큰 기능을 작은 구현 단위로 나누고, 가장 먼저 작동 가능한 최소 기능 제품(MVP)을 정합니다.
* **일관된 프로젝트 구조**: 폴더, 파일, 실행 방식의 일관성을 유지합니다.
* **점진적 구현 및 검증**: 기능 구현, 오류 분석, 테스트, 리팩토링을 작은 이터레이션 단위로 반복합니다.
* **산출물 문서화**: README, 분석 보고서, 테스트 시나리오 등을 빠짐없이 기록합니다.

### 2) 사용 대상
* **재직자 AI 서비스 개발 과정 수강생** 및 AI 페어 프로그래밍 실습 참여자
* 다양한 AI 개발 에이전트를 연동해 자신만의 AI 서비스를 빌드하려는 학습자
* 설계 문서화, 오류 디버깅, 애자일 백로그 관리 및 테스트 계획 수립이 낯선 입문자
* 팀 프로젝트에서 팀원 간 및 AI 에이전트 간의 **공통 개발 절차와 협업 규칙**이 필요한 팀

> [!NOTE]
> 특정 프로그래밍 언어나 웹 프레임워크에 종속되지 않으므로 Python, JavaScript, TypeScript, FastAPI, Flask, React, Streamlit 등 모든 스택의 프로젝트에 적용할 수 있습니다.

---

## 2. 대상 개발 툴 및 배포 프레임워크

통합 설치 스크립트(`install.ps1`/`install.sh`)를 사용하여 대상 개발 툴의 특성과 전역 설정 경로에 맞춰 프레임워크를 연동합니다. 설치 시 공통 에셋 폴더(`./common/`) 안의 규칙 파일들이 대상 툴의 명칭 규칙에 맞게 자동으로 분기 배포 및 변수 치환됩니다.

| 설치 유형 | 대상 개발 툴 | 변환 적용 및 특징 | 설치 경로 |
| --- | --- | --- | --- |
| **`gemini`** | **Antigravity (Google Gemini)** | `./common/AGENTS.md` ➡️ `AGENTS.md` (Gemini용 치환)<br>`./common/RULES.md` ➡️ `RULES.md` 복사 (14개 스킬) | `~/.gemini/config` |
| **`claude`** | **Claude (Desktop / Code CLI)** | `./common/AGENTS.md` ➡️ `CLAUDE.md` (Claude용 치환)<br>`./common/RULES.md` ➡️ `RULES.md` 복사 (14개 스킬) | `~/.claude` |
| **`codex`** | **Codex (Cursor 등)** | `./common/AGENTS.md` ➡️ `AGENTS.md` (Codex용 치환)<br>`./common/RULES.md` ➡️ `RULES.md` 복사 (14개 스킬) | `~/.codex` |

---

## 3. Kit가 제공하는 개발 흐름

이 Kit는 아래의 9단계 흐름을 기본 개발 프로세스로 채택하여 에이전트가 수강생을 안내하도록 규정합니다.

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

### 단계별 상세 목적 및 역할

| 단계 | 목적 | 설명 |
| --- | --- | --- |
| **요구사항 정의** | 서비스 목표 및 범위 확정 | 개발할 서비스의 타겟 사용자, 해결하고자 하는 핵심 문제, 필수 기능을 명확히 정의합니다. |
| **기능 분해** | 단위 작업 쪼개기 | 큰 아이디어와 기능 정의를 입력, 처리, 출력, 예외 처리 등 구현 가능한 최소 단위로 분할합니다. |
| **MVP 설계** | 핵심 가치 제품 정의 | 최우선으로 완성해 동작을 검증할 최소 기능 제품(MVP)의 구체적인 범위를 규정합니다. |
| **프로젝트 구조 생성** | 구조의 일관성 확보 | 파일 및 폴더 배치와 실행 엔트리 포인트를 정해진 표준 구조에 따라 생성합니다. |
| **기능 구현** | 설계 기반 코드 빌드 | 도메인 모델 및 API 명세를 바탕으로 에이전트와 함께 작은 기능별 구현을 점진적으로 진행합니다. |
| **오류 분석** | 디버깅 및 에러 로깅 | 실행 에러 발생 시 로그와 트레이스를 기반으로 원인을 명확히 파악하고 수정안을 도출합니다. |
| **테스트** | 신뢰성 검증 | 작성된 기능이 설계 스펙과 일치하는지 단위 테스트 코드 또는 수동 확인 시나리오를 통해 확인합니다. |
| **리팩토링** | 가독성 및 가치 최적화 | 작동을 유지한 상태에서 중복 코드를 제거하고 모듈화 및 코드 품질을 개선합니다. |
| **README / 보고서** | 최종 산출물 정리 | 프로젝트의 설치법, 구조, 결과 및 문제 해결 과정을 상세히 기록하여 완료 보고서를 작성합니다. |

---

## 4. 설치 및 제거 방법

저장소 루트의 통합 인스톨러를 실행하면 공통 소스 폴더(`./common/`)에 속한 에셋들을 스캔하고, 텍스트 문서 내의 템플릿 변수(`{{AGENT_NAME}}`, `{{INSTALL_PATH}}` 등)를 타겟 툴 환경에 맞게 치환하여 지정된 설치 경로 아래에 플랫(Flat)하게 배포합니다.

### 1) Windows 환경 (PowerShell)
* **설치 명령**:
  ```powershell
  # 대화식 선택 설치 (원격 저장소 주소는 선택 사항)
  powershell -ExecutionPolicy Bypass -File .\install\install.ps1

  # 또는 특정 툴 명시 설치
  powershell -ExecutionPolicy Bypass -File .\install\install.ps1 -Tool gemini -GitUrl https://github.com/your-org/your-repo.git
  powershell -ExecutionPolicy Bypass -File .\install\install.ps1 -Tool claude -GitUrl https://github.com/your-org/your-repo.git
  powershell -ExecutionPolicy Bypass -File .\install\install.ps1 -Tool codex -GitUrl https://github.com/your-org/your-repo.git
  ```
* **제거 명령**:
  ```powershell
  # 대화식 선택 제거
  powershell -ExecutionPolicy Bypass -File .\install\uninstall.ps1

  # 또는 특정 툴 명시 제거
  powershell -ExecutionPolicy Bypass -File .\install\uninstall.ps1 -Tool gemini
  ```

### 2) macOS / Linux 환경 (Bash)
* **설치 명령**:
  ```bash
  # 스크립트 실행 권한 부여
  chmod +x install/install.sh install/uninstall.sh

  # 대화식 선택 설치
  ./install/install.sh

  # 또는 특정 툴 명시 설치
  ./install/install.sh -t gemini -g https://github.com/your-org/your-repo.git
  ./install/install.sh -t claude -g https://github.com/your-org/your-repo.git
  ./install/install.sh -t codex -g https://github.com/your-org/your-repo.git
  ```
* **제거 명령**:
  ```bash
  # 대화식 선택 제거
  ./install/uninstall.sh

  # 또는 특정 툴 명시 제거
  ./install/uninstall.sh -t gemini
  ```

---

## 5. 저장소 상세 구조 및 파일 역할 안내

이 프로젝트는 공통 설계 에셋이 들어있는 `./common/` 폴더, 설치 스크립트가 포함된 `./install/` 폴더, 그리고 작업 히스토리를 아카이빙하는 `./walkthrough/` 폴더로 물리적 구조가 나누어져 있습니다.

```text
vibe-frame-kit_custom/
├── README.md (루트 공통 안내서)
├── AGENTS.md (저장소 자체 개발 시 AI 에이전트가 따를 지침서)
├── config.toml (프로젝트 설정 파일 샘플)
├── common/ (공통 개발 프레임워크 원본 에셋)
│   ├── AGENTS.md (치환용 에이전트별 상세 규칙 원본)
│   ├── RULES.md (에이전트 제어용 공통 규칙 원본)
│   ├── agents/
│   │   └── routing.md (에이전트 역할 라우팅 매핑 정의)
│   ├── skills/ (14개 기본 AI 스킬 꾸러미)
│   │   ├── requirements-definition/ (요구사항 정의 가이드)
│   │   ├── function-breakdown/ (기능 분해 가이드)
│   │   ├── mvp-planning/ (MVP 설계 가이드)
│   │   ├── project-structure-builder/ (프로젝트 폴더 구조 가이드)
│   │   ├── api-service-builder/ (API 명세 설계 가이드)
│   │   ├── ai-agent-workflow-builder/ (에이전트 워크플로우 설계 가이드)
│   │   ├── debugging-coach/ (오류 분석 및 디버깅 가이드)
│   │   ├── refactoring-coach/ (코드 품질 개선 가이드)
│   │   ├── readme-report-writer/ (README 및 최종 보고서 가이드)
│   │   ├── security-checker/ (API 키 노출 등 보안 점검 가이드)
│   │   ├── domain-model-builder/ (도메인 모델 설계 가이드)
│   │   ├── backlog-planning/ (스프린트 백로그 가이드)
│   │   ├── context-map-builder/ (프로젝트 컨텍스트 관리 가이드)
│   │   └── test-planning-coach/ (테스트 설계 가이드)
│   ├── prompts/ (12개 이터레이션용 한글 프롬프트 템플릿)
│   ├── templates/ (11개 필수 산출물 표준 마크다운 템플릿)
│   ├── config/ (스킬 구성 및 TOML 환경 설정 파일)
│   ├── docs/ (수강생/강사용 가이드북 및 보안 체크리스트)
│   └── study/ (애자일, API, 워크플로우 등 개념 학습 가이드)
├── install/ (통합 인스톨러 스크립트)
│   ├── install.ps1 / install.sh (설치 스크립트)
│   └── uninstall.ps1 / uninstall.sh (제거 스크립트)
└── walkthrough/ (AI 에이전트의 개발 작업 이력 보존 폴더)
```

### 각 항목별 기능 정의

| 분류 | 대상 경로 / 파일 | 역할 및 상세 내용 |
| --- | --- | --- |
| **에이전트 규칙** | `AGENTS.md` / `CLAUDE.md` | 에이전트가 점진적 협업, MVP 준수, 한국어 응답 등의 규칙을 준수하며 개발하도록 제어하는 상세 규칙 지침서 |
| **공통 필수 규칙** | `RULES.md` | 작업 완료 보고서(Walkthrough) 생성 및 Git 자동화 제어 조건이 명시된 프로세스 지침 |
| **무시 설정 파일** | `.cursorignore` / `.geminiignore` / `.gitignore` | 불필요한 파일 인덱싱을 차단하여 컨텍스트 토큰을 절약하고 민감 데이터 유출을 막는 보안 필터 파일들 |
| **프로젝트 설정** | `config.toml` / `common/config/` | 프레임워크 동작 설정 파일 및 Antigravity 등 스킬 구성 목록(`lean-skills.txt` 등) 정의 파일들 |
| **에이전트 라우팅** | `common/agents/routing.md` | 개발의 각 절차 단계별로 필요한 에이전트 스킬 매핑 정의 문서 |
| **AI 스킬 모음** | `common/skills/` | 기능 분해, 디버깅, 도메인 설계, 보안 점검 등 14개 주요 작업에 필요한 에이전트 맞춤형 지침서(SKILL.md) 세트 |
| **프롬프트 템플릿** | `common/prompts/` | 학습자가 에이전트와 대화를 시작할 때 복사하여 편리하게 투입 가능한 12단계 한글 프롬프트 파일들 |
| **산출물 표준 양식** | `common/templates/` | 요구사항 정의서, MVP 설계서 등 일관성 있는 산출물 빌드를 지원하는 마크다운 템플릿 표준 양식 |
| **수동/자동 테스트** | `common/skills/test-planning-coach/` | 단위 테스트 시나리오 작성법 및 테스트 코드 자동 생성을 위한 보조 지침 |
| **가이드 및 체크리스트**| `common/docs/` | 수강생 전용 활용법(`student-guide`), 교수자 가이드(`instructor-guide`), 실습 보안 체크리스트 등 안내 문서 폴더 |
| **이론 학습 보조** | `common/study/` | 설계 및 구현 프로세스 중 이론적 개념 습득이 필요할 때 에이전트에 주입하여 지식을 탐색하게 돕는 보조 자료들 |
| **통합 인스톨러** | `install/` (`install.ps1`, `install.sh` 등) | Windows PowerShell 및 macOS/Linux Bash 쉘 환경에서 프레임워크를 1초 만에 배포 및 완전 복구·제거하는 스크립트 모음 |
| **작업 이력 보고서** | `walkthrough/` | 에이전트가 작업 완료 단계에서 사용자 승인을 획득해 자동으로 작성·축적해 나가는 마크다운 작업 보고서 보관 폴더 |

---

### `config.toml` 설정 규격 상세 안내

저장소 루트에 위치한 `config.toml` 파일은 Vibe Frame Kit의 제어 스위치 및 에이전트의 동작 속성을 커스텀하는 기준 파일입니다.

```toml
[project]
name = "my-ai-service-project"        # 진행할 AI 서비스 프로젝트명

[agent]
name = "Gemini"                       # 에이전트 툴 명칭 (Gemini, Claude, Codex 등)
install_path = "~/.gemini/config"     # 에이전트가 설치되어 관리되는 전역 설정 주소
rules_file = "AGENTS.md"              # 해당 에이전트가 로드해서 해석할 규칙 파일 이름
config_file = "config.toml"           # 에이전트 설정 파일의 명칭

[walkthrough]
enable_generation = true              # 작업 완료 시 walkthrough/ 내 보고서 자동 생성 활성화 스위치
enable_metadata_logging = true        # 보고서에 사용 모델명, 작업 시간, 토큰 정보 강제 기재 여부 스위치

[git]
auto_commit_push = true               # 작업 완료 후 한글 커밋 메시지를 적용하여 add/commit/push하도록 유도하는 자동화 스위치
remote_repository_url = "https://..." # 프로젝트 원격 Git 리포지토리 URL (스크립트 설치 시 자동 주입 가능)
```

> [!TIP]
> * `auto_commit_push` 옵션을 `true`로 설정하면 원격 URL 주소와 연동하여 커밋 및 푸시 가이드라인을 에이전트가 직접 제안하거나 제어합니다. 만약 원격 URL이 비어 있는 경우 설치기가 이 옵션을 자동으로 `false`로 격하시켜 오류를 예방합니다.

---

## 6. 에이전트 협업 사용 예시

예를 들어 **"AI 회의록 요약 서비스"**를 만드는 수강생 프로젝트를 진행한다고 가정합니다.

1. **시작**: `templates/requirements-template.md`을 기반으로 에이전트와 대화하며 대상 사용자와 해결할 핵심 문제를 정리하여 요구사항 정의서를 작성합니다.
2. **분해**: `prompts/02-function-breakdown.md` 프롬프트를 에이전트에 주입하여 주요 기능을 구현 가능한 파트별로 조각냅니다.
3. **스펙 설정**: `templates/mvp-plan-template.md`을 기준으로 첫 번째 프로토타입에 포함할 "최소 가치 기능(예: 오디오 업로드 및 STT 텍스트 변환)"만 필터링합니다.
4. **구조 잡기**: 에이전트에게 MVP 기능을 개발하기 위한 기본 폴더 구조와 초기 파일 생성을 지시합니다.
5. **구현 및 로깅**: 기능 구현 중 난관이나 에러를 만났을 때, 에이전트와 `skills/debugging-coach`를 활용해 에러 전체 스택을 전달하고 상세 해결 로그를 도출해 냅니다.
6. **검증**: 구현 완료 후 `templates/test-scenario-template.md`에 맞추어 테스트 시나리오를 설계하고 로컬 검증을 거칩니다.
7. **리팩토링 및 문서화**: 코드 구조 개선 후 프로젝트 완료를 위해 README 및 최종 보고서를 에이전트 안내에 따라 일괄 작성합니다.

> **💡 에이전트 요청 모범 예문 (수강생 ➡️ 에이전트)**
> ```text
> 나는 'AI 회의록 요약 서비스'를 개발하고 있어.
> 지금은 '요구사항 정의' 단계를 진행하려고 해.
> 설치된 스킬 중 'requirements-definition' 가이드를 바탕으로, 
> 프로젝트의 목표, 핵심 대상 사용자, MVP 범위를 단계적 대화를 통해 정의해줘.
> ```

---

## 7. 주의사항

* **코드 직접 확인**: 에이전트가 작성한 코드 및 쉘 명령어는 맹신하지 말고 작동 구조와 의도를 수강생 본인이 직접 검토·실행해야 합니다.
* **작은 점진적 단위**: 한 번에 너무 방대한 분량의 코드를 요청하면 에이전트의 기억(컨텍스트) 범위가 초과하여 코드가 꼬이거나 생략될 수 있으므로, 기능 하나씩 작성과 검증을 반복하세요.
* **상세 로그 전달**: 에러 발생 시 "안 돼요" 대신 전체 에러 메시지와 발생 전후의 상황, 관련 코드 전체를 제공해야 디버깅 성공률이 높습니다.
* **설계 동기화**: 개발 도중 요구사항이나 아키텍처 스펙이 달라질 경우, 반드시 관련된 요구사항 정의서나 MVP 문서를 함께 최신 상태로 갱신하여 에이전트가 예전 설계대로 구현하는 것을 미연에 방지해야 합니다.

---

## 8. 보안 안내 및 키 관리 수칙

AI 서비스 개발 실습 중 API 키, 인증 토큰 등의 유출을 차단하기 위한 필수 보안 규칙입니다.

* **`.env` 커밋 절대 금지**: API Key나 크레덴셜 정보가 포함된 로컬 환경 변수 파일(`.env`, `.env.local` 등)은 절대 공용 Git 저장소에 커밋하지 마세요. (각 프레임워크 인스톨 시 `.gitignore`에 규칙이 자동 추가됩니다)
* **`.env.example` 활용**: 저장소에는 민감 정보가 생략된 뼈대 파일(`.env.example`)만 올려 가짜 값(`your_api_key_here` 등)으로 사용법만 명시하세요.
* **대화창 내 키 입력 금지**: 에이전트와의 일반 채팅 대화나 프롬프트 입력 칸에 직접적인 실서버 비밀번호나 원천 API 인증 토큰을 직접 텍스트로 적어서 전송하지 않도록 주의하세요.
* **자체 보안 점검**: 프로젝트 배포 및 최종 제출을 진행하기 전에, 반드시 설치된 `skills/security-checker`를 활용하여 유출된 기밀 정보가 없는지 정밀 검사를 수행하는 것을 강력히 권장합니다.

```env
# .env 파일 보안 예시
OPENAI_API_KEY=your_real_api_key_here   # ❌ 이 상태로 커밋하면 절대 안 됨!
DATABASE_URL=postgresql://user:pass@localhost:5432/db
```

---

## 9. 저작권 및 라이선스 안내 (Attribution & License)

* **원본 저작물 출처**: 이 프로젝트는 [PieterKim/vibe-frame-kit](https://github.com/PieterKim/vibe-frame-kit.git) 원본 저장소를 기반으로 합니다.
* **프로젝트 성격**: 본 저장소는 원본 저작물인 `vibe-frame-kit`을 교육 실습 환경 및 특정 AI 에이전트(Gemini, Claude, Codex 등) 최적화 목적에 맞게 변경하고 개선한 **커스터마이징 수정안(Customized version)**입니다.
* **라이선스 규정**:
  - 원본 저작물은 **MIT License**를 따릅니다.
  - 본 수정본 역시 원본의 라이선스 규정을 상속하며, 자유로운 복제, 수정, 배포 및 상업적 이용이 허용됩니다. 단, 원본 저작자 및 라이선스 고지 사항은 유지되어야 합니다.
