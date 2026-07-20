# GitHub 업로드 전 보안 체크리스트

이 문서는 수강생이 AI 서비스 프로젝트를 GitHub에 올리기 전에 반드시 확인해야 하는 보안 체크리스트입니다.

특히 API Key, token, password, `.env`, `credentials.json`, `auth.json`, 개인정보 포함 데이터는 절대 공개 저장소에 올리면 안 됩니다.

## 1. GitHub에 올리면 안 되는 파일

아래 항목이 프로젝트에 포함되어 있는지 확인하세요.

- [ ] `.env` 파일이 GitHub에 올라가지 않는다.
- [ ] `.env.local` 파일이 GitHub에 올라가지 않는다.
- [ ] `.env.*` 파일이 GitHub에 올라가지 않는다.
- [ ] `token.json` 파일이 GitHub에 올라가지 않는다.
- [ ] `auth.json` 파일이 GitHub에 올라가지 않는다.
- [ ] `credentials.json` 파일이 GitHub에 올라가지 않는다.
- [ ] `*.pem`, `*.key`, `*.p12`, `*.pfx` 같은 인증 키 파일이 올라가지 않는다.
- [ ] `*.sqlite`, `*.db` 같은 로컬 DB 파일이 올라가지 않는다.
- [ ] `logs/` 폴더가 올라가지 않는다.
- [ ] `cache/` 폴더가 올라가지 않는다.
- [ ] `sessions/` 폴더가 올라가지 않는다.
- [ ] `private/` 폴더가 올라가지 않는다.
- [ ] `customer-data/` 폴더가 올라가지 않는다.
- [ ] `uploads/` 폴더에 실제 사용자 파일이 들어 있지 않다.

`.gitignore`에는 최소한 다음 항목이 포함되어야 합니다.

```gitignore
.env
.env.*
!.env.example
token.json
auth.json
credentials.json
*.pem
*.key
*.sqlite
*.db
logs/
cache/
sessions/
private/
customer-data/
uploads/
```

## 2. .env와 .env.example 차이

`.env`와 `.env.example`은 역할이 다릅니다.

| 파일 | GitHub 업로드 | 설명 |
| --- | --- | --- |
| `.env` | 올리면 안 됨 | 실제 API Key, token, password를 저장합니다. |
| `.env.example` | 올려도 됨 | 필요한 환경 변수 이름과 가짜 예시 값을 보여줍니다. |

확인하세요.

- [ ] `.env`에는 실제 API Key가 들어 있다.
- [ ] `.env`는 `.gitignore`에 포함되어 있다.
- [ ] `.env.example`에는 실제 값이 없다.
- [ ] `.env.example`에는 `your_api_key_here` 같은 가짜 값만 있다.
- [ ] README에는 `.env.example`을 복사해 `.env`를 만들라고 안내되어 있다.

좋은 `.env.example` 예시:

```env
OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
DATABASE_URL=your_database_url_here
```

## 3. API Key 관리 방법

API Key는 코드에 직접 작성하지 않습니다.

확인하세요.

- [ ] Python 코드에 실제 API Key를 직접 적지 않았다.
- [ ] JavaScript/TypeScript 코드에 실제 API Key를 직접 적지 않았다.
- [ ] README에 실제 API Key를 적지 않았다.
- [ ] 최종 보고서에 실제 API Key를 적지 않았다.
- [ ] 오류 로그에 API Key가 출력되지 않는다.
- [ ] API Key는 `.env`에만 저장했다.
- [ ] 코드에서는 환경 변수로 API Key를 불러온다.

나쁜 예시:

```python
api_key = "sk-..."
```

좋은 예시:

```python
import os

api_key = os.getenv("OPENAI_API_KEY")
```

## 4. 개인정보 포함 데이터 처리 방법

AI 서비스 프로젝트에서는 사용자 입력, 업로드 파일, 로그에 개인정보가 들어갈 수 있습니다.

개인정보 예시:

- 이름
- 이메일
- 전화번호
- 주소
- 주민등록번호
- 회사 내부 문서
- 회의록 원문
- 고객 상담 기록
- 고객 리뷰 원본

확인하세요.

- [ ] 실제 개인정보가 포함된 데이터 파일을 GitHub에 올리지 않았다.
- [ ] 샘플 데이터는 가짜 데이터 또는 가명 처리된 데이터만 사용했다.
- [ ] 로그 파일에 사용자 입력 원문이 남아 있지 않다.
- [ ] 업로드 파일 폴더가 `.gitignore`에 포함되어 있다.
- [ ] README나 보고서에 실제 개인정보를 적지 않았다.
- [ ] 테스트 예시는 `user@example.com`, `010-0000-0000` 같은 가짜 값을 사용했다.

## 5. 민감정보 검색 명령어

GitHub에 push하기 전에 아래 명령어로 민감정보 후보를 검색하세요.

일반 민감정보 검색:

```bash
rg -n "API_KEY|TOKEN|PASSWORD|SECRET|CLIENT_SECRET|ACCESS_TOKEN|REFRESH_TOKEN"
```

환경 변수 이름 검색:

```bash
rg -n "OPENAI_API_KEY|GEMINI_API_KEY|GOOGLE_API_KEY|ANTHROPIC_API_KEY"
```

인증 파일 검색:

```bash
rg --files | rg "credentials\.json|auth\.json|token\.json|\.env$|\.env\."
```

OpenAI API Key 형태 검색:

```bash
rg -n "sk-[A-Za-z0-9_-]+"
```

Google API Key 형태 검색:

```bash
rg -n "AIza[0-9A-Za-z_-]+"
```

Git에 추적 중인 민감 파일 검색:

```bash
git ls-files | rg "\.env|credentials\.json|auth\.json|token\.json|\.pem|\.key|\.sqlite|\.db"
```

확인하세요.

- [ ] 검색 결과에 실제 API Key가 없다.
- [ ] 검색 결과에 token이 없다.
- [ ] 검색 결과에 password가 없다.
- [ ] 검색 결과에 `.env` 파일이 없다.
- [ ] 검색 결과에 `credentials.json`, `auth.json`, `token.json`이 없다.

## 6. push 전 체크리스트

GitHub에 push하기 전에 최종 확인하세요.

- [ ] `git status`로 올라갈 파일 목록을 확인했다.
- [ ] `.env` 파일이 Git 추적 대상에 없다.
- [ ] `.env.example`에는 가짜 예시 값만 있다.
- [ ] API Key, token, password가 코드에 직접 적혀 있지 않다.
- [ ] `credentials.json`, `auth.json`, `token.json`이 포함되어 있지 않다.
- [ ] 로컬 DB 파일 `*.sqlite`, `*.db`가 포함되어 있지 않다.
- [ ] 로그, 캐시, 세션 폴더가 포함되어 있지 않다.
- [ ] 실제 고객 데이터나 개인정보 데이터가 포함되어 있지 않다.
- [ ] README에 실제 비밀값이 없다.
- [ ] 최종 보고서에 실제 비밀값이 없다.
- [ ] `.gitignore`가 보안 파일을 충분히 제외하고 있다.
- [ ] Codex에 보안 점검을 요청했다.

Codex 요청 예시:

```text
GitHub에 push하기 전에 민감정보와 보안 위험을 점검해줘.
API Key, token, password, credentials.json, auth.json, .env 파일이 포함되어 있는지 확인해줘.
민감정보가 발견되면 실제 값은 출력하지 말고 파일 위치와 조치 방법만 알려줘.
```

## 7. 사고 발생 시 조치 방법

만약 API Key나 비밀번호를 GitHub에 올렸다면 즉시 조치해야 합니다.

확인하세요.

- [ ] 유출된 API Key를 즉시 폐기했다.
- [ ] 새 API Key를 발급했다.
- [ ] `.env`에 새 API Key를 저장했다.
- [ ] 코드나 README에서 실제 값을 제거했다.
- [ ] `.gitignore`에 누락된 항목을 추가했다.
- [ ] GitHub 저장소에 남아 있는 민감정보를 제거했다.
- [ ] 팀 프로젝트라면 팀원과 강사에게 상황을 공유했다.
- [ ] 같은 실수가 반복되지 않도록 push 전 체크리스트를 다시 수행했다.

중요:

```text
공개 GitHub 저장소에 올라간 API Key는 이미 노출된 것으로 간주해야 합니다.
단순히 파일에서 삭제하는 것만으로는 충분하지 않습니다.
반드시 해당 Key를 폐기하고 새로 발급하세요.
```

