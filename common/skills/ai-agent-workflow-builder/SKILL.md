---
name: ai-agent-workflow-builder
description: 여러 단계의 AI 처리 흐름, 도구 사용 및 상태 관리 방식을 설계합니다.
---
# AI Agent Workflow Builder

## 1. 목적
이 Skill의 목적은 AI Agent 또는 LangGraph 기반 workflow를 설계하는 것입니다.

## 2. 사용 상황
- AI 처리가 여러 단계로 나뉘는 경우
- 입력 내용에 따라 다른 처리 경로가 필요할 때
- 검색, 요약, 분류, 생성, 검증을 연계해야 할 때

## 3. 입력 정보
- 요구사항 정의서와 기능 분해 목록.
- 사용 모델 및 LangGraph 사용 가능 여부 정보.

## 4. 작업 절차 및 템플릿 참조 규칙
1. 에이전트는 다음 경로의 템플릿을 동적으로 로드(`view_file`)하여 작성 항목을 파악합니다: `{{INSTALL_PATH}}/templates/agent-workflow-template.md`.
2. 에이전트 목록(역할, 입출력)을 정의하고, 순차 처리 또는 조건 분기 중심의 워크플로우 흐름 다이어그램을 설계합니다.
3. LangGraph 확장 적용을 위한 State 정의와 Node/Edge 구조 및 검증 에이전트(Validator)의 실패 시 피드백 루프를 명세합니다.
4. 수강생이 에이전트 역할 분담 법칙, State 정의 팁, 조건 분기 다이어그램 예시를 원할 경우, `{{INSTALL_PATH}}/study/agent-workflow-study.md` 문서를 안내하거나 조회해 인용하십시오.

## 5. 에이전트 설계 주의사항
- MVP 단계에서는 에이전트 노드의 개수를 3~4개 이하로 최소화하여 시도합니다.
- 상태(State) 값은 전역 노드가 공통적으로 접근해야 하는 핵심 데이터만 한정해 정의합니다.
