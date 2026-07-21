# 도메인 및 데이터 모델 명세서 (Domain Model Specification)

## 1. 핵심 엔티티 정의

* 서비스 비즈니스 흐름을 구성하는 주요 데이터 객체(Entity)와 그 의미, 연관된 관계들을 정의합니다.

| 엔티티명 | 설명 | 관계 (Relations) |
| --- | --- | --- |
| User | 서비스 로그인 및 프로필을 보유한 사용자 | Meeting (1:N) |
| Meeting | 회의록 메인 데이터 객체 | Summary (1:1), Task (1:N) |
| Task | 요약 결과로 도출된 할 일 항목 | Meeting (N:1) |

## 2. 데이터 속성 명세

* 각 엔티티의 필드명, 데이터 타입, 필수 여부 및 간단한 설명을 기록합니다.

### A. Meeting (회의)

- **PrimaryKey**: `id` (UUID 또는 AutoIncrement ID)
- **Attributes**:
  - `title` (String, Required) - 회의 제목
  - `raw_text` (Text, Required) - 회의 원본 녹취록 텍스트
  - `created_at` (DateTime, Default: Now) - 생성 일시
  - `owner_id` (ForeignKey -> User.id) - 회의록 소유자 ID

### B. Task (할 일)

- **PrimaryKey**: `id` (UUID 또는 AutoIncrement ID)
- **Attributes**:
  - `content` (String, Required) - 할 일 내용
  - `is_completed` (Boolean, Default: False) - 완료 여부
  - `due_date` (DateTime, Optional) - 마감 기한
  - `meeting_id` (ForeignKey -> Meeting.id) - 연결된 회의 ID

## 3. 스키마 예시 (Python Pydantic 또는 DB DDL)

* 구현 언어/프레임워크에 맞는 구체적인 스키마 구조 코드를 작성합니다.

```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class MeetingBase(BaseModel):
    title: str = Field(..., example="7월 주간 기획 회의")
    raw_text: str = Field(..., example="회의 내용 텍스트...")

class MeetingResponse(MeetingBase):
    id: str
    created_at: datetime
    owner_id: str
```

## 4. 모의 데이터 (Mock Data) 예시

* 프론트엔드 연동 및 API 시뮬레이션을 위한 데이터 예시를 JSON 형식으로 작성합니다.

```json
{
  "id": "meet-9812",
  "title": "7월 주간 기획 회의",
  "raw_text": "철수: 다음 주까지 로그인 기능을 개발하겠습니다. 영희: 저는 UI 시안을 보완할게요.",
  "created_at": "2026-07-19T10:30:00Z",
  "owner_id": "user-001"
}
```
