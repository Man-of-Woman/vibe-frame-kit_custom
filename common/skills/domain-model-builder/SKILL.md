---
name: domain-model-builder
description: 요구사항 정의서와 MVP 계획을 바탕으로 데이터 엔티티 구조와 데이터 모델을 설계합니다.
---
# Domain Model Builder

## 1. 목적

이 Skill의 목적은 요구사항 정의서와 MVP 계획을 바탕으로 데이터 엔티티 구조와 데이터 모델을 설계하는 것입니다.

Antigravity는 설계 및 API 구현 단계 전에 핵심 비즈니스 도메인 모델과 데이터베이스(또는 Pydantic 모델) 구조를 정의해야 합니다. 이로 인해 데이터 일관성을 확보하고, 구현 실패를 대폭 줄일 수 있습니다.

## 2. 사용 상황

- 요구사항 정의서가 작성되고 MVP 범위가 결정된 경우
- 데이터베이스 설계(테이블 구조, 관계)가 필요한 경우
- API의 Request/Response 데이터 구조를 사전에 정비하고 싶을 때
- 비즈니스 로직에 관여하는 핵심 객체(Entity)와 그 속성을 정의해야 할 때

## 3. 입력 정보

- 요구사항 정의서 및 MVP 범위 계획서
- 필요한 데이터의 종류와 성격
- 사용할 데이터베이스 종류(SQL, NoSQL 등)
- 데이터 저장 및 보존 기간 제약 조건

## 4. 작업 절차

1. 핵심 비즈니스 명사(Entity) 식별 및 나열 (예: User, Meeting, Summary)
2. 각 엔티티의 속성(Attribute) 및 데이터 타입(DataType) 정의
3. 엔티티 간의 관계(Relation) 정의 (1:N, N:M 등)
4. 스키마 명세서(Pydantic Schema 또는 ORM Model 등) 초안 도출
5. 가짜 데이터(Mock Data) 예시 작성하여 데이터 정합성 사전 검증

## 5. 산출물 형식

Antigravity는 도메인 모델 설계 결과를 Markdown 문서 형식으로 작성하며, 다음 항목을 반드시 포함해야 합니다.

- 핵심 엔티티 정의 표
- 데이터 속성 명세 (타입 및 제약조건 포함)
- 데이터베이스 DDL 또는 ORM 클래스 예시 코드
- 데이터 예시 (JSON 포맷 권장)

## 6. 도메인 모델 명세서 템플릿

`{{INSTALL_PATH}}/templates/domain-model-template.md` 파일의 형식을 기본 템플릿으로 사용하여 도메인 모델 명세서를 작성합니다.
