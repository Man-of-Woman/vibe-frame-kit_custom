# API 설계 및 구현(API Service Builder) 학습 가이드

이 문서는 FastAPI 기반 백엔드 API 설계 시 레이어(Layer) 분리 원칙, Request/Response 설계 모범안, Pydantic 스키마 정의, 예외 처리 설계 및 Swagger 테스트 기법의 학습 가이드와 모범 예제입니다.

## 1. Request / Response 설계 베스트 프랙티스
* **Request 설계**: 필수 입력값과 선택값 분리, 입력 형식 명시. API Key나 비밀번호 등 민감 정보를 바디(Body)에 직접 받지 않는 흐름 권장.
* **Response 설계**: 성공 상태 및 결과 가시성을 높이는 필드 설계. 오류 발생 시 일관된 디테일(`detail` 필드 등) 반환.
  - **좋은 응답 예시**:
    ```json
    {
      "summary": "회의 핵심 요약입니다.",
      "action_items": ["자료 정리", "피드백 분석"],
      "message": "요약이 완료되었습니다."
    }
    ```
  - **나쁜 응답 예시**:
    ```json
    { "data": "끝" }
    ```

---

## 2. API 레이어(router, service, schema) 분리 규칙
역할과 책임을 확실하게 격리하여 유지보수성을 극대화합니다.

| 레이어 (Layer) | 저장 위치 | 핵심 역할 |
| --- | --- | --- |
| **router** | `app/api/routes/` | HTTP Endpoints 정의, 요청 파라미터 수신 및 최종 Response schema 반환 |
| **schema** | `app/api/schemas/` | Pydantic 기반의 Request/Response 데이터 검증 및 데이터 구조체 선언 |
| **service** | `app/services/` | 실제 AI API(OpenAI, Gemini 등) 호출, DB 읽기/쓰기, 비즈니스 연산 수행 |

---

## 3. 예외 및 오류 처리 설계
* 입력값 부재 또는 형식 검증 오류: `400 Bad Request` 또는 `422 Unprocessable Entity` 반환.
* 외부 AI API 연동 실패 (Gemini, OpenAI 연결 차단 등): `502 Bad Gateway` 또는 `500 Internal Server Error` 반환.
* 보안 주의사항: 에러 응답 및 Stack trace 로그에 절대 API Key나 환경 변수 비밀값이 출력되지 않도록 설계할 것.

---

## 4. 실제 API 명세 및 구현 예시 (회의록 요약 API)

### 1. API 명세
* **Endpoint**: `POST /api/summarize`
* **설명**: 회의록 텍스트를 입력받아 요약과 후속 할 일 목록 반환.
* **성공**: `200 OK`
* **실패**: `400 Bad Request`, `502 Bad Gateway`

### 2. Request / Response Pydantic 스키마 예제
```python
from pydantic import BaseModel, Field

class SummarizeRequest(BaseModel):
    text: str = Field(..., min_length=1, description="요약할 회의록 텍스트")

class SummarizeResponse(BaseModel):
    summary: str
    action_items: list[str]
    message: str
```

### 3. 파일 배치 예시 구조
```text
backend/
└── app/
    ├── main.py
    ├── api/
    │   ├── routes/
    │   │   └── summarize.py
    │   └── schemas/
    │       └── summarize.py
    └── services/
        └── summarize_service.py
```
