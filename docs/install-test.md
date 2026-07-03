# 설치 테스트 절차

이 문서는 `vibe-frame-kit`이 실제로 설치 가능한지 확인하기 위한 테스트 절차입니다.

Windows와 macOS/Linux 환경을 나누어 테스트합니다.

## Windows 기준 테스트 절차

### 1. 저장소 clone

PowerShell을 열고 테스트용 폴더에서 저장소를 내려받습니다.

```powershell
git clone https://github.com/your-org/vibe-frame-kit.git
cd vibe-frame-kit
```

실제 수업 저장소 주소가 있다면 `your-org` 부분을 해당 주소로 바꿉니다.

### 2. 설치 스크립트 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

정상 설치되면 설치 완료 메시지가 출력되어야 합니다.

### 3. ~/.codex 폴더 확인

```powershell
dir $HOME\.codex
```

다음 항목이 보여야 합니다.

```text
AGENTS.md
agents
skills
config
```

### 4. AGENTS.md 설치 확인

```powershell
Test-Path $HOME\.codex\AGENTS.md
Get-Content -Encoding UTF8 $HOME\.codex\AGENTS.md | Select-Object -First 5
```

확인 기준:

- `True`가 출력됩니다.
- `AGENTS.md` 상단 내용이 한국어로 표시됩니다.

기존 `AGENTS.md`가 있었다면 아래와 같은 백업 파일도 생성될 수 있습니다.

```text
AGENTS.md.backup.yyyymmdd-hhmmss
```

### 5. skills 설치 확인

```powershell
dir $HOME\.codex\skills
```

다음 Skill 폴더가 보여야 합니다.

```text
requirements-definition
function-breakdown
mvp-planning
project-structure-builder
api-service-builder
ai-agent-workflow-builder
debugging-coach
refactoring-coach
readme-report-writer
security-checker
```

개별 Skill 파일도 확인합니다.

```powershell
Test-Path $HOME\.codex\skills\requirements-definition\SKILL.md
```

### 6. config 설치 확인

```powershell
dir $HOME\.codex\config
```

다음 파일이 보여야 합니다.

```text
lean-skills.txt
codex.config.sample.toml
```

내용 확인:

```powershell
Get-Content -Encoding UTF8 $HOME\.codex\config\lean-skills.txt
```

### 7. Codex App 또는 CLI에서 확인할 프롬프트

새 프로젝트 폴더로 이동한 뒤 Codex를 실행합니다.

```powershell
mkdir test-ai-service
cd test-ai-service
codex
```

Codex App을 사용하는 경우에는 `test-ai-service` 폴더를 열고 아래 프롬프트를 입력합니다.

```text
나는 AI 회의록 요약 서비스를 만들고 싶어.
이 프로젝트를 요구사항 정의 단계부터 시작해줘.
Vibe Frame Kit의 개발 흐름에 따라 요구사항 정의서 초안을 작성해줘.
```

확인 기준:

- Codex가 한국어로 응답합니다.
- 바로 전체 코드를 만들지 않고 요구사항 정의부터 시작합니다.
- 프로젝트 개요, 해결 문제, 대상 사용자, 입력 데이터, 핵심 기능, MVP 범위를 정리합니다.

### 8. 설치 실패 시 점검 방법

| 문제 | 점검 방법 |
| --- | --- |
| 스크립트 실행이 막힘 | `powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1`로 실행했는지 확인합니다. |
| `scripts\install.ps1`을 찾을 수 없음 | 현재 위치가 `vibe-frame-kit` 루트인지 확인합니다. |
| `~/.codex`에 파일이 없음 | 설치 중 오류 메시지를 확인하고 스크립트를 다시 실행합니다. |
| 한글이 깨져 보임 | `Get-Content -Encoding UTF8`로 다시 확인합니다. |
| 기존 `AGENTS.md`가 사라진 것 같음 | `AGENTS.md.backup.*` 파일이 생성되었는지 확인합니다. |
| Skill 폴더가 일부 없음 | 저장소가 최신인지 확인하고 다시 clone합니다. |

## macOS/Linux 기준 테스트 절차

### 1. 저장소 clone

터미널을 열고 테스트용 폴더에서 저장소를 내려받습니다.

```bash
git clone https://github.com/your-org/vibe-frame-kit.git
cd vibe-frame-kit
```

실제 수업 저장소 주소가 있다면 `your-org` 부분을 해당 주소로 바꿉니다.

### 2. 설치 스크립트 실행

먼저 실행 권한을 부여합니다.

```bash
chmod +x scripts/install.sh
```

설치 스크립트를 실행합니다.

```bash
./scripts/install.sh
```

정상 설치되면 설치 완료 메시지가 출력되어야 합니다.

### 3. ~/.codex 폴더 확인

```bash
ls -la ~/.codex
```

다음 항목이 보여야 합니다.

```text
AGENTS.md
agents
skills
config
```

### 4. AGENTS.md 설치 확인

```bash
test -f ~/.codex/AGENTS.md && echo "AGENTS.md installed"
head -n 5 ~/.codex/AGENTS.md
```

확인 기준:

- `AGENTS.md installed`가 출력됩니다.
- `AGENTS.md` 상단 내용이 한국어로 표시됩니다.

기존 `AGENTS.md`가 있었다면 아래와 같은 백업 파일도 생성될 수 있습니다.

```text
AGENTS.md.backup.yyyymmdd-hhmmss
```

### 5. skills 설치 확인

```bash
ls ~/.codex/skills
```

다음 Skill 폴더가 보여야 합니다.

```text
requirements-definition
function-breakdown
mvp-planning
project-structure-builder
api-service-builder
ai-agent-workflow-builder
debugging-coach
refactoring-coach
readme-report-writer
security-checker
```

개별 Skill 파일도 확인합니다.

```bash
test -f ~/.codex/skills/requirements-definition/SKILL.md && echo "requirements-definition installed"
```

### 6. config 설치 확인

```bash
ls ~/.codex/config
```

다음 파일이 보여야 합니다.

```text
lean-skills.txt
codex.config.sample.toml
```

내용 확인:

```bash
cat ~/.codex/config/lean-skills.txt
```

### 7. Codex App 또는 CLI에서 확인할 프롬프트

새 프로젝트 폴더로 이동한 뒤 Codex를 실행합니다.

```bash
mkdir test-ai-service
cd test-ai-service
codex
```

Codex App을 사용하는 경우에는 `test-ai-service` 폴더를 열고 아래 프롬프트를 입력합니다.

```text
나는 AI 회의록 요약 서비스를 만들고 싶어.
이 프로젝트를 요구사항 정의 단계부터 시작해줘.
Vibe Frame Kit의 개발 흐름에 따라 요구사항 정의서 초안을 작성해줘.
```

확인 기준:

- Codex가 한국어로 응답합니다.
- 바로 전체 코드를 만들지 않고 요구사항 정의부터 시작합니다.
- 프로젝트 개요, 해결 문제, 대상 사용자, 입력 데이터, 핵심 기능, MVP 범위를 정리합니다.

### 8. 설치 실패 시 점검 방법

| 문제 | 점검 방법 |
| --- | --- |
| `Permission denied`가 발생함 | `chmod +x scripts/install.sh`를 실행했는지 확인합니다. |
| `scripts/install.sh`를 찾을 수 없음 | 현재 위치가 `vibe-frame-kit` 루트인지 확인합니다. |
| `~/.codex`에 파일이 없음 | 설치 중 오류 메시지를 확인하고 스크립트를 다시 실행합니다. |
| 기존 `AGENTS.md`가 사라진 것 같음 | `ls ~/.codex/AGENTS.md.backup.*`로 백업 파일을 확인합니다. |
| Skill 폴더가 일부 없음 | 저장소가 최신인지 확인하고 다시 clone합니다. |
| Codex가 Kit 흐름을 따르지 않음 | `~/.codex/AGENTS.md`와 `~/.codex/skills`가 설치되었는지 다시 확인합니다. |

