---
name: api-service-builder
description: 백엔드 API 명세 작성 및 Request/Response 구조와 엔드포인트를 구현합니다.
---
# API Service Builder

## 1. 목적
이 Skill의 목적은 FastAPI 기반 API 서비스를 설계하고 구현하는 것입니다.

## 2. 사용 상황
- FastAPI 기반 백엔드 API를 설계해야 할 때
- AI 요약, 분류, 추천, 검색 등의 기능을 API 형태로 노출해야 할 때
- 프론트엔드와 연결할 Request/Response 양식이 필요할 때

## 3. 입력 정보
- 요구사항 정의서와 기능 분해 목록.
- 백엔드 개발 언어 사양(FastAPI 및 Python) 정보.

## 4. 작업 절차 및 템플릿 참조 규칙
1. 에이전트는 다음 경로의 템플릿을 동적으로 로드(`view_file`)하여 작성 항목을 파악합니다: `{{INSTALL_PATH}}/templates/api-spec-template.md`.
2. API Router, Pydantic Schema, Service 레이어 간의 역할 분리를 보장하면서 API Router 엔드포인트 명세를 설계합니다.
3. 설계된 API 명세 구조에 따라 Swagger 테스트 계획 및 코드를 작성하고 결과를 문서화합니다.
4. 수강생이 레이어 아키텍처 설계 기준, Pydantic 작성 팁, 예외 처리 설계 원칙 및 예시를 요청할 경우, `{{INSTALL_PATH}}/study/api-service-study.md` 파일을 안내 또는 참조하도록 설계하십시오.

## 5. 설계 주의사항
- router 내부에는 직접 AI 호출(Gemini 등)이나 비즈니스 로직을 서술하지 않고 router ➡️ service 위임 구조로 구성합니다.
- 오류 응답 본문에 API Key나 서버 환경 변수가 유출되지 않도록 상세히 방어해야 합니다.
