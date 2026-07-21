# 테스트 설계 및 자동화(Test Planning Coach) 학습 가이드

이 문서는 개발한 백엔드 API 및 비즈니스 로직을 검증하기 위한 테스트 시나리오 설계 원칙과 수강생들이 가장 어려워하는 **AI 모델 호출(외부 API) 모킹(Mocking) 테스트 코드 작성 예제**입니다.

## 1. 테스트 시나리오 작성 시 3대 체크포인트
1. **정상 경로 (Happy Path)**: 올바른 입력값을 보냈을 때 정상적으로 `200 OK`와 정합한 데이터를 반환하는가?
2. **경계값 및 빈 입력 (Edge/Empty Cases)**: 빈 텍스트 입력, 너무 긴 텍스트 입력 등의 상황에서 오류 처리 핸들러가 `400 Bad Request` 등 규정된 에러를 올바르게 내놓는가?
3. **외부 연동 실패 (Exception Handling)**: OpenAI/Gemini 등 외부 API가 타임아웃 되거나 인증 실패(401)할 때 시스템이 뻗지 않고 일관된 에러 메시지를 반환하는가?

---

## 2. AI API Mocking 테스트 코드 예제 (Python pytest)
AI 호출을 실제로 유료 API 요금을 소모하지 않고 로컬에서 테스트하기 위해 `unittest.mock`을 사용해 가짜 응답(Mock)을 만드는 구조입니다.

```python
import pytest
from unittest.mock import AsyncMock, patch
from app.services.summarize_service import summarize_text

@pytest.mark.asyncio
@patch("app.services.summarize_service.client.aio.models.generate_content")
async def test_summarize_text_success(mock_generate_content):
    # 1. 가짜 AI 응답 객체 설정 (Mocking)
    mock_response = AsyncMock()
    mock_response.text = "이것은 모킹된 요약 결과입니다."
    mock_generate_content.return_value = mock_response

    # 2. 실제 함수 호출
    result = await summarize_text("오늘 회의에서는 피드백 분석 일정을 논의했습니다.")

    # 3. 단언 (Assertion)
    assert result["summary"] == "이것은 모킹된 요약 결과입니다."
    assert "action_items" in result
    mock_generate_content.assert_called_once()
```
