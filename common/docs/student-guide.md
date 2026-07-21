# 수강생 가이드

이 문서는 재직자 AI 서비스 개발 과정 수강생이 `vibe-frame-kit`을 설치하고 사용하는 방법을 설명합니다.

{{AGENT_NAME}}가 코드를 대신 전부 만들어주는 도구라고 생각하기보다, 프로젝트를 단계별로 함께 정리하고 구현을 도와주는 개발 보조자라고 생각하면 좋습니다.

## 1. Vibe Frame Kit 소개

Vibe Frame Kit는 AI 서비스 프로젝트를 진행할 때 공통 개발 흐름을 따르도록 도와주는 설정 모음입니다.

이 Kit에는 다음 자료가 포함되어 있습니다.

| 항목 | 설명 |
| --- | --- |
| `{{RULES_FILE}}` | {{AGENT_NAME}}가 따라야 할 공통 행동 규칙 |
| `agents/` | 작업 단계별 라우팅 기준 |
| `skills/` | 요구사항 정의, MVP 설계, 오류 분석 등 작업별 지침 |
| `prompts/` | 수강생이 복사해서 사용할 수 있는 프롬프트 |
| `templates/` | 요구사항 정의서, MVP 계획서, 보고서 등 제출용 양식 |
| `config/` | Skill 목록과 샘플 설정 |
| `scripts/` | 설치 스크립트 |

## 2. 설치 전 준비사항

설치 전 아래 항목을 확인합니다.

| 준비사항 | 설명 |
| --- | --- |
| {{AGENT_NAME}} 사용 환경 | {{AGENT_NAME}} CLI 또는 {{AGENT_NAME}} 앱을 사용할 수 있어야 합니다. |
| Git | GitHub에서 저장소를 내려받을 때 사용합니다. |
| PowerShell | Windows에서 설치 스크립트를 실행할 때 사용합니다. |
| 프로젝트 폴더 | AI 서비스 프로젝트를 만들 작업 폴더를 준비합니다. |

Windows 사용자는 PowerShell을 사용하는 것을 기준으로 설명합니다.

## 3. GitHub에서 Kit 다운로드

GitHub에 업로드된 저장소를 내려받습니다.

```powershell
git clone https://github.com/your-org/vibe-frame-kit.git
cd vibe-frame-kit
```

아직 실제 GitHub 주소가 정해지지 않았다면, 강사가 제공한 저장소 주소를 사용합니다.

압축 파일로 받은 경우에는 압축을 풀고 해당 폴더로 이동합니다.

```powershell
cd vibe-frame-kit
```

## 4. install.ps1 실행 방법

Windows PowerShell에서 아래 명령을 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\install\install.ps1
```

설치 스크립트는 프로젝트의 Git 원격 저장소 주소를 필수로 입력받습니다. 입력한 주소는 이후 `config.toml`의 `[git].remote_repository_url` 기본값으로 반영됩니다.

이 명령은 현재 Kit의 다음 항목을 사용자 폴더의 `{{INSTALL_PATH}}`로 복사합니다.

| 복사 대상 | 설치 위치 |
| --- | --- |
| `{{RULES_FILE}}` | `{{INSTALL_PATH}}/{{RULES_FILE}}` |
| `agents/` | `{{INSTALL_PATH}}/agents/` |
| `skills/` | `{{INSTALL_PATH}}/skills/` |
| `config/` | `{{INSTALL_PATH}}/config/` |
| `prompts/` | `{{INSTALL_PATH}}/prompts/` |
| `templates/` | `{{INSTALL_PATH}}/templates/` |
| `docs/` | `{{INSTALL_PATH}}/docs/` |

기존 `{{INSTALL_PATH}}/{{RULES_FILE}}`가 있으면 자동으로 백업됩니다.

## 5. 설치 확인 방법

설치가 끝나면 PowerShell에서 아래 명령으로 확인합니다.

```powershell
dir {{INSTALL_PATH}}
```

다음 항목이 보이면 설치가 정상적으로 된 것입니다.

```text
{{RULES_FILE}}
agents
skills
config
prompts
templates
docs
```

Skill 폴더도 확인할 수 있습니다.

```powershell
dir {{INSTALL_PATH}}\skills
```

`requirements-definition`, `mvp-planning`, `debugging-coach` 같은 폴더가 보이면 됩니다.

## 6. 프로젝트 폴더에서 {{AGENT_NAME}} 실행 방법

Kit 설치 후에는 실제 프로젝트 폴더로 이동해서 {{AGENT_NAME}}를 사용합니다.

예시:

```powershell
cd C:\projects\my-ai-service
```

그 다음 {{AGENT_NAME}}를 실행합니다.

```powershell
{{AGENT_NAME}}
```

{{AGENT_NAME}} 앱을 사용하는 경우에는 프로젝트 폴더를 열고, 해당 폴더 안에서 작업을 시작하면 됩니다.

중요한 점은 Kit 폴더가 아니라, 내가 만들 AI 서비스 프로젝트 폴더에서 {{AGENT_NAME}}를 실행하는 것입니다.

## 7. 첫 요청 예시

처음부터 "전체 서비스를 만들어줘"라고 요청하기보다 요구사항 정의부터 시작하는 것이 좋습니다.

좋은 첫 요청:

```text
나는 AI 회의록 요약 서비스를 만들고 싶어.
사용자는 회의 녹취록을 가진 직장인이야.
텍스트를 입력하면 핵심 안건, 결정 사항, 할 일 목록을 요약해주는 서비스를 만들고 싶어.
먼저 요구사항 정의서부터 작성해줘.
```

아이디어가 아직 막연하다면 이렇게 요청해도 됩니다.

```text
AI 서비스 프로젝트 아이디어가 아직 명확하지 않아.
내가 관심 있는 분야는 [분야]이고, 수업 시간 안에 만들 수 있는 프로젝트 주제를 같이 정리해줘.
```

## 8. 개발 흐름

이 Kit는 다음 개발 흐름을 기본으로 사용합니다.

```text
요구사항 정의
→ 기능 분해
→ MVP 설계
→ 프로젝트 구조 생성
→ 기능 구현
→ 오류 분석
→ 테스트
→ 리팩토링
→ README / 보고서 작성
```

각 단계에서 {{AGENT_NAME}}에게 요청할 수 있는 예시는 다음과 같습니다.

| 단계 | 요청 예시 |
| --- | --- |
| 요구사항 정의 | `이 아이디어를 요구사항 정의서로 정리해줘.` |
| 기능 분해 | `요구사항을 실제 구현 가능한 기능 단위로 나눠줘.` |
| MVP 설계 | `수업 시간 안에 실행 가능한 MVP 범위를 정해줘.` |
| 프로젝트 구조 생성 | `MVP 기준으로 FastAPI 프로젝트 구조를 만들어줘.` |
| 기능 구현 | `파일 업로드 기능만 먼저 구현해줘.` |
| 오류 분석 | `이 오류 로그를 보고 원인과 해결 방법을 알려줘.` |
| 테스트 | `이 기능을 어떻게 테스트하면 되는지 알려줘.` |
| 리팩토링 | `기존 기능은 유지하면서 코드 구조를 정리해줘.` |
| 문서화 | `README와 최종 보고서 초안을 작성해줘.` |

## 9. 오류 발생 시 요청 방법

오류가 발생하면 에러 메시지 일부만 보내지 말고, 실행 상황과 전체 로그를 함께 보내야 합니다.

좋은 요청:

```text
아래 오류를 로그와 코드 기준으로 분석해줘.

실행한 명령어:
uvicorn app.main:app --reload

기대했던 동작:
FastAPI 서버가 실행되는 것

오류 로그:
[여기에 전체 오류 로그 붙여넣기]

관련 파일:
app/main.py
app/api/routes/summarize.py
```

{{AGENT_NAME}}에게 요청할 때는 다음을 함께 알려주면 좋습니다.

| 항목 | 예시 |
| --- | --- |
| 실행 명령 | `uvicorn app.main:app --reload` |
| 기대한 동작 | 서버 실행, API 응답, 화면 표시 등 |
| 실제 오류 | 전체 오류 로그 |
| 관련 파일 | 오류에 나온 파일 경로 |
| 최근 변경 | 방금 수정한 파일이나 설치한 패키지 |

## 10. README 작성 요청 방법

프로젝트가 어느 정도 동작하면 README를 작성해야 합니다.

요청 예시:

```text
현재 프로젝트를 기준으로 GitHub README 초안을 작성해줘.

포함할 내용:
- 프로젝트 소개
- 주요 기능
- 기술 스택
- 프로젝트 구조
- 설치 방법
- 환경 변수 설정 방법
- 실행 방법
- API 사용 방법
- 테스트 방법
- 향후 개선 사항

실제 API Key나 .env 값은 포함하지 말아줘.
```

최종 보고서도 함께 필요하면 이렇게 요청합니다.

```text
README와 함께 수업 제출용 최종 보고서 초안도 작성해줘.
구현 과정, 오류 해결 과정, 테스트 결과, 한계점, 향후 개선 사항을 포함해줘.
```

## 11. GitHub 업로드 전 보안 점검

GitHub에 올리기 전에는 반드시 보안 점검을 해야 합니다.

특히 다음 파일과 값은 GitHub에 올리면 안 됩니다.

| 올리면 안 되는 항목 | 이유 |
| --- | --- |
| `.env` | 실제 API Key와 비밀번호가 들어갈 수 있습니다. |
| API Key | 외부 API 비용이 발생하거나 계정이 노출될 수 있습니다. |
| token | 인증 권한이 탈취될 수 있습니다. |
| password | 계정 정보가 노출됩니다. |
| `credentials.json` | Google API 등 인증 정보가 들어갈 수 있습니다. |
| `auth.json` | 인증 정보가 들어갈 수 있습니다. |
| 고객 데이터 | 개인정보 또는 회사 자료가 포함될 수 있습니다. |

{{AGENT_NAME}}에게 이렇게 요청하세요.

```text
GitHub에 push하기 전에 민감정보와 보안 위험을 점검해줘.
API Key, token, password, credentials.json, auth.json, .env 파일이 포함되어 있는지 확인해줘.
민감정보가 발견되면 실제 값은 출력하지 말고 파일 위치와 조치 방법만 알려줘.
```

## 12. 자주 하는 실수

| 실수 | 왜 문제인가 | 좋은 방법 |
| --- | --- | --- |
| 처음부터 전체 시스템을 만들어 달라고 요청함 | 범위가 너무 커져 실패하기 쉽습니다. | 요구사항 정의와 MVP 설계부터 시작합니다. |
| 오류 로그 일부만 보냄 | 원인을 정확히 찾기 어렵습니다. | 전체 로그와 실행 명령을 함께 보냅니다. |
| `.env`를 GitHub에 올림 | API Key가 노출될 수 있습니다. | `.env`는 올리지 않고 `.env.example`만 올립니다. |
| README를 마지막에 대충 작성함 | 실행 방법과 결과를 설명하기 어렵습니다. | 개발 중간부터 README를 업데이트합니다. |
| 기능을 너무 많이 넣으려 함 | 수업 시간 안에 완성하기 어렵습니다. | MVP에 필요한 기능만 먼저 구현합니다. |
| 기존 코드를 확인하지 않고 수정 요청함 | 정상 동작하던 기능이 깨질 수 있습니다. | 관련 파일을 먼저 확인해 달라고 요청합니다. |
| 테스트하지 않고 완료했다고 생각함 | 실제 실행에서 오류가 날 수 있습니다. | 실행 명령과 테스트 방법으로 확인합니다. |

프로젝트를 진행할 때 가장 중요한 기준은 작게 만들고, 실행해보고, 기록하는 것입니다.

## 13. 완료 보고서(Walkthrough) 및 Git 자동 커밋/푸시 설정 제어

프로젝트 관리의 연속성을 보장하기 위해, 이 프레임워크는 작업 완료 시 **완료 보고서(Walkthrough) 작성**과 **Git 커밋/푸시 유도** 자동화 규칙을 탑재하고 있습니다. 이 동작은 프로젝트 루트의 `config.toml`에서 필요에 따라 직접 On/Off 제어할 수 있습니다.

### 1) 설정 항목 및 의미
`config.toml`의 하단에 추가된 옵션을 통해 에이전트의 완료 행동을 제어합니다.

```toml
[walkthrough]
# 작업 완료 단계에서 walkthrough/ 폴더 하위에 완료 보고서 자동 생성을 유도할지 여부
enable_generation = true
# 보고서 상단에 지시사항 원문, 사용한 AI 모델, 수행 시간, 소모 토큰을 기록할지 여부
enable_metadata_logging = true

[git]
remote_repository_url = "https://github.com/your-org/your-repo.git"
# 작업 완료 및 승인 후 자동으로 git add, commit, push 명령어를 가이드하거나 proposal할지 여부
auto_commit_push = true
# Git 커밋 메시지를 한글 기반으로 가이드할지 여부
korean_commit_message = true
```

### 2) 사용 팁
- **과제 제출 단계**: 보고서와 기여도 기록을 남기기 위해 `enable_generation`과 `auto_commit_push`를 모두 `true`로 설정하고 실습하는 것을 권장합니다.
- **순수 개발 단계**: 매 단순 수정 작업마다 완료 보고서나 푸시 안내를 유발하는 것이 번거롭다면, 이 값들을 `false`로 꺼서 보다 신속하고 유연한 코딩 세션을 유지할 수 있습니다.
