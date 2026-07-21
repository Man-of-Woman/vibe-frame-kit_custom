---
name: readme-report-writer
description: 프로젝트 README 및 제출용 최종 보고서 작성을 돕습니다.
---
# README Report Writer

## 1. 목적
이 Skill의 목적은 프로젝트 제출용 README와 최종 보고서를 작성하는 것입니다.

## 2. 사용 상황
- 프로젝트 제출 전 README를 정리해야 할 때
- 실행 방법과 API 사용 방법을 문서화해야 할 때
- 최종 보고서 초안 작성이 필요할 때

## 3. 입력 정보
- 구현된 소스 코드 구조 및 Swagger API 명세 정보.
- 요구사항 정의서와 기능 분해, MVP 계획서 최종 데이터.

## 4. 작업 절차 및 템플릿 참조 규칙
1. 에이전트는 다음 경로의 두 템플릿을 동적으로 로드(`view_file`)하여 작성 항목을 파악합니다:
   - README용: `{{INSTALL_PATH}}/templates/readme-template.md`
   - 최종 보고서용: `{{INSTALL_PATH}}/templates/final-report-template.md`
2. 구현 완료된 코드베이스 실제 사양에 맞춰 환경 변수 설정법, 폴더 트리 구조, API Endpoint, 그리고 테스트 통과 여부 표를 채워 작성합니다.
3. 수강생이 포트폴리오용 기술 스택 기술 방법, 실행 명령어 안내 예제, 보고서 오류 극복 항목 작성 팁을 요청할 경우, `{{INSTALL_PATH}}/study/readme-report-study.md` 파일을 안내 또는 참조하도록 유도하십시오.

## 5. 문서 작성 주의사항
- 실제 API Key나 환경 변수 비밀키 데이터는 절대 완성된 문서에 노출하지 않습니다.
- 구현되지 않은 허위 사양은 작성하지 않으며 실제 시연 및 테스트 통과된 사항 위주로 기획-설계-검증 스토리를 완성합니다.
