# AI 에이전트 워크플로우 설계(Agent Workflow Builder) 학습 가이드

이 문서는 LangGraph 또는 멀티 에이전트 기반 설계 시 에이전트 역할 분담 법칙, State(상태) 설계, Node/Edge 조건 분기 설계 및 결과물 검증(Validator) 에이전트 설계의 학습용 해설과 다이어그램 예시입니다.

## 1. 멀티 에이전트 역할 분해 기준
하나의 큰 AI 작업을 각각의 독립된 전문 에이전트로 쪼개어 연동함으로써 결과물 품질을 통제합니다.

* **핵심 에이전트 역할**:
  - `Input Analyzer`: 입력값을 분석하고 어떤 도구/경로가 필요한지 판단.
  - `Retriever`: 벡터 스토어, DB, 또는 검색 엔진 등에서 데이터 수집.
  - `Processor / Generator`: 수집된 데이터를 바탕으로 본문/코드 생성.
  - `Validator`: 생성 결과물이 필수 항목을 만족하는지, 오류는 없는지 교차 검증.
  - `Formatter`: 최종 답변을 마크다운 표, JSON 등으로 정리.

---

## 2. LangGraph 확장 및 State(상태) 설계법
LangGraph 프레임워크로 확장 시 아래 4요소의 개념을 바탕으로 설계합니다.

* **State**: 워크플로우 전체 노드 간에 실시간 공유되는 메모리 격차 (Python TypedDict 기반).
* **Node**: 에이전트의 역할 또는 API 함수.
* **Edge**: 다음 노드로의 정적 연결 흐름.
* **Conditional Edge**: 상태(State) 값의 boolean 또는 enum 판단에 따른 조건 분기 연결.

### State(상태) 정의 예시 (Python)
```python
from typing import TypedDict

class WorkflowState(TypedDict):
    user_input: str
    task_type: str
    needs_retrieval: bool
    retrieved_context: list[str]
    draft_output: str
    validation_passed: bool
    final_output: str
```

---

## 3. 에이전트 워크플로우 다이어그램 예시 (텍스트 구조)
```text
[Start] ➡️ [Input Analyzer] (작업 유형 판단)
                ⬇️
          {조건 분기: needs_retrieval?}
          ├─ True  ➡️ [Retriever] (근거 검색) ➡️ [Generator]
          └─ False ➡️ [Generator] (답변 작성)
                ⬇
          [Validator] (형식 및 누락 검증)
                ⬇
          {검증 통과 여부?}
          ├─ Pass ➡️ [Formatter] ➡️ [End]
          └─ Fail ➡️ [Generator]로 복귀하여 재생성 유도
```
