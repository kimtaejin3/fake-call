# AI Fake Call — MVP PRD (요약본, 구현 지침)

## 제품 한 줄 설명
전화가 오는 것에서 끝나지 않고, 받은 이후 AI가 실제 목소리로 사용자와 20~40초 상호작용하는 가짜통화 앱. 핵심 메시지: "받아도 안 들키는 가짜통화"

## 핵심 사용자 플로우
앱 실행 → Caller 선택 → Scenario 선택 → Delay 선택 → 가짜 수신 화면 → 수락 → AI가 먼저 말함 → 20~40초 대화 → 자연스러운 종료 → 피드백

## 화면 목록 (필수 7 + 선택 1)
1. Splash
2. Home — 타이틀 "AI Fake Call", 부제 "곤란한 순간, 자연스럽게 빠져나오세요.", 메인 CTA "가짜전화 받기" 하나만.
3. Caller Selection — 제목 "누가 전화할까요?" / 항목: 엄마, 아빠, 친구, 직장 상사, 연인
4. Scenario Selection — 제목 "왜 전화했나요?" / 항목: "빨리 집에 들어오라고 해줘", "급한 일이 있다고 해줘", "회사에 문제가 생겼다고 해줘", "자연스럽게 통화해줘"
5. Delay Selection — 제목 "언제 전화할까요?" / 옵션: 지금, 10초 후, 30초 후, 1분 후, 3분 후
6. Incoming Call — 전체화면. Caller 이름, 프로필 이미지, 수신 애니메이션, 거절/응답 버튼, 진동, 벨소리
7. Active Call — Caller 이름, 통화시간 타이머(00:23 형식), 아바타, 스피커/마이크 버튼, 통화 종료 버튼
8. Call Complete — "통화가 종료되었습니다." + 👍도움이 됐어요/👎별로였어요 + "실제로 이런 상황에서 사용할 것 같나요?" 5점 척도

## 데이터 모델
Caller: { id, name, voiceId, avatarUrl, persona }
Scenario: { id, title, prompt, firstMessage, recommendedDuration, enabled }
CallSession: { userId, callerId, scenarioId, startedAt, endedAt, duration, completed, feedback }

초기 데이터 (하드코딩 Fake Data — MVP Phase 1):
- Callers: mom(엄마), dad(아빠), friend(친구), boss(직장 상사), partner(연인)
- Scenarios: come_home("빨리 집에 들어오라고 해줘", firstMessage "여보세요? 너 지금 어디야?"), urgent("급한 일이 있다고 해줘"), work_problem("회사에 문제가 생겼다고 해줘"), casual("자연스럽게 통화해줘")
- Delays: 0, 10, 30, 60, 180 (초)

## 기술 스택
- Flutter + Dart, 상태관리 Riverpod (flutter_riverpod), 라우팅 go_router
- Feature-first architecture
- Firebase(Auth/Firestore/Analytics/Crashlytics)는 Phase 4 — 지금은 연동하지 않고 인터페이스만 추상화
- Voice AI는 Phase 3 — 지금은 VoiceService 인터페이스 + Mock 구현(스크립트 재생)만

## 폴더 구조
```
lib/
  core/
    router/
    theme/
    services/        # timer, ringtone, vibration, (voice: interface + mock)
  features/
    home/presentation/
    caller/data/ domain/ presentation/
    scenario/data/ domain/ presentation/
    fake_call/domain/ presentation/ application/   # delay 선택, incoming call
    voice_call/data/ domain/ presentation/ application/  # active call
    feedback/presentation/ application/
  shared/
    widgets/
    models/
```

## 디자인 원칙
- Minimal, Modern, Dark, Premium, Native Call UI 느낌
- 장난감/Prank 앱 느낌 금지, 과도한 네온 금지, 복잡한 설정 금지
- 가짜전화 실행까지 탭 3~4회 이내
- Incoming/Active Call 화면은 iOS/Android 시스템 전화 UI에서 크게 벗어나지 않게

## MVP에서 하지 않을 것
CallKit, Android Telecom, 실제 전화망, PSTN, 목소리 복제, 커스텀 캐릭터, 긴 자유대화, 녹음, 통화 전체 저장, 소셜, 결제, 광고, Watch, Widget, Background incoming call

## 첫 번째 개발 목표 시나리오
엄마 / "집에 빨리 들어오라고 해줘" / 30초 후 → 가짜 전화 수신 → 수락 → AI 첫마디 "여보세요? 너 지금 어디야?" → 20~40초 대화(Mock: 스크립트) → "그래. 조심해서 들어와."로 종료 → 피드백 화면

## 개발 순서 (Phase 1~2 이번 범위)
1. 프로젝트 초기화, Theme + Router
2. Home → Caller → Scenario → Delay 화면
3. Timer / Ringtone / Vibration / Incoming Call UI
4. Active Call UI (Mock 대화: 통화시간 타이머, 스크립트 진행)
5. Call Complete + 피드백
Phase 3(실제 Voice AI), Phase 4(Firebase)는 이후 별도 진행.
