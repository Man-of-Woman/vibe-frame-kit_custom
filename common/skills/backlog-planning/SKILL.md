---
name: backlog-planning
description: MVP 릴리즈 이후 피드백을 수집하여 차기 스프린트(Sprint 2)를 위한 백로그 우선순위와 계획을 수립합니다.
---
# Backlog Planning

## 1. 목적

이 Skill의 목적은 MVP(Sprint 1) 빌드 완료 및 릴리즈 테스트 이후, 유저 피드백과 누락된 요구사항을 바탕으로 차기 스프린트(Sprint 2) 개발을 기획하는 것입니다.

Antigravity는 단순히 일회성(Waterfall) 개발로 끝내지 않고, 피드백 순환 구조를 통해 제품을 점진적으로 고도화하기 위한 백로그 우선순위를 산정해야 합니다.

## 2. 사용 상황

- MVP 버전의 기본적인 개발 및 작동 테스트가 완료된 상태
- MVP 릴리즈 이후 버그 리포트나 개선 아이디어가 수집되었을 때
- 다음 단계 개발(Sprint 2)에서 무엇을 먼저 구현할지 계획해야 할 때
- 프로젝트 이터레이션(Iteration) 관리가 필요할 때

## 3. 입력 정보

- 이전 MVP 개발 결과물 및 테스트 scenario 결과 리포트
- 사용자 혹은 테스트 중 발생한 개선 의견 및 버그 리포트
- 전체 개발 요구사항 목록 중 MVP에서 보류(제외)되었던 기능 목록

## 4. 작업 절차

1. MVP 테스트 결과 발생한 버그 및 개선사항 수집
2. 백로그 분류: 버그 수정(Hotfix), 사용성 개선(Enhancement), 신규 기능 추가(Feature)
3. MoSCoW 기법(Must Have, Should Have, Could Have, Won't Have)을 활용한 우선순위 산정
4. 차기 이터레이션(Sprint 2) 목표 설정 및 작업 일정 조율

## 5. 산출물 형식

Antigravity는 백로그 계획 결과를 Markdown 문서 형식으로 작성하며, 다음 항목을 반드시 포함해야 합니다.

- 이전 이터레이션 피드백 요약
- MoSCoW 기반 우선순위 백로그 리스트
- 다음 스프린트 목표 및 일정 계획

## 6. 백로그 계획서 템플릿

`templates/backlog-plan-template.md` 파일의 형식을 기본 템플릿으로 사용하여 백로그 계획서를 작성합니다.
