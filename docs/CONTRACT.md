# 구현 계약 (모든 구현 에이전트는 이 문서를 따를 것)

이미 존재하는 파일 (수정 금지, import해서 사용):
- `lib/shared/models/caller.dart` — `Caller { id, name, voiceId, avatarUrl?, persona, emoji }`
- `lib/shared/models/scenario.dart` — `Scenario { id, title, prompt, firstMessage, recommendedDuration, enabled }`
- `lib/shared/data/app_data.dart` — `kCallers`, `kScenarios`, `kDelayOptions` (`DelayOption { label, seconds }`)
- `lib/core/router/routes.dart` — 라우트 경로 상수 `Routes.home` 등
- `lib/features/fake_call/application/call_setup_provider.dart` — `callSetupProvider` (`CallSetup { caller?, scenario?, delay? }`, notifier에 `selectCaller/selectScenario/selectDelay/reset`)

## 화면 클래스 및 파일 경로 (정확히 이 이름으로 만들 것)
| 라우트 | 클래스 | 파일 |
|---|---|---|
| `Routes.home` | `HomeScreen` | `lib/features/home/presentation/home_screen.dart` |
| `Routes.callerSelect` | `CallerSelectScreen` | `lib/features/caller/presentation/caller_select_screen.dart` |
| `Routes.scenarioSelect` | `ScenarioSelectScreen` | `lib/features/scenario/presentation/scenario_select_screen.dart` |
| `Routes.delaySelect` | `DelaySelectScreen` | `lib/features/fake_call/presentation/delay_select_screen.dart` |
| `Routes.incomingCall` | `IncomingCallScreen` | `lib/features/fake_call/presentation/incoming_call_screen.dart` |
| `Routes.activeCall` | `ActiveCallScreen` | `lib/features/voice_call/presentation/active_call_screen.dart` |
| `Routes.callComplete` | `CallCompleteScreen` | `lib/features/feedback/presentation/call_complete_screen.dart` |

모든 화면은 인자 없는 생성자(`const XxxScreen({super.key})`). 선택 상태는 전부 `callSetupProvider`에서 읽는다.

## 테마 (AppTheme)
- `lib/core/theme/app_theme.dart` — `AppTheme.dark` (ThemeData). 다크 전용.
- 색: 배경 `#0A0A0C`, 표면 `#16161A`, 강조(accent) `#4ADE80`(수락/CTA), 위험 `#EF4444`(거절/종료), 텍스트 주 `#F5F5F7`, 보조 `#8E8E93`
- Minimal·Premium·Native Call UI 느낌. 네온/장난감 느낌 금지.

## 내비게이션 플로우
Home CTA → callerSelect → scenarioSelect → delaySelect → (선택 완료 시) incomingCall 로 이동.
- delaySelect에서 옵션 탭 → `selectDelay` 후 `context.go(Routes.incomingCall)`.
- IncomingCallScreen이 내부에서 delay만큼 대기(검은 화면 + "N초 후 전화가 옵니다" 카운트다운 표시) 후 수신 UI + 벨소리/진동 시작.
- 응답 → `context.go(Routes.activeCall)`, 거절 → 벨소리 정지 후 `context.go(Routes.home)` + reset.
- ActiveCall 종료 → `context.go(Routes.callComplete)`.
- Complete에서 피드백 선택 → `reset()` 후 `context.go(Routes.home)`.

## 서비스
- `lib/core/services/ringtone_service.dart` — `RingtoneService` : audioplayers로 `assets/audio/ringtone.wav` 루프 재생 `start()`, `stop()`. `HapticFeedback.vibrate()` 주기 반복 포함.
- `lib/core/services/voice_service.dart` — `abstract class VoiceService { Future<void> start(...); Stream<String> aiMessages; ... }` + `MockVoiceService`: 시나리오별 스크립트 라인을 타이밍에 맞춰 순차 방출(실제 음성 없음, 화면에 자막처럼 표시). come_home 스크립트: "여보세요? 너 지금 어디야?" → (4초) "아빠가 너 찾고 있어. 조금 일찍 들어와." → (5초) "응. 좀 빨리 왔으면 좋겠어." → (5초) "그래. 조심해서 와." → 통화 자동 종료.

## 규칙
- Riverpod(flutter_riverpod) + go_router 사용. 이미 pubspec에 추가되어 있음.
- 새 패키지 추가 금지.
- 주석/문자열은 한국어 UI 텍스트 그대로, 코드 식별자는 영어.
- `flutter analyze` 통과 가능한 코드.
