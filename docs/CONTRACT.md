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
| `Routes.home` | `ShellScreen` (하단 탭: `HomeTab`/`HistoryTab`/`SettingsTab`) | `lib/features/shell/presentation/shell_screen.dart` (홈 탭: `lib/features/home/presentation/home_tab.dart`) |
| `Routes.incomingCall` | `IncomingCallScreen` | `lib/features/fake_call/presentation/incoming_call_screen.dart` |
| `Routes.activeCall` | `ActiveCallScreen` | `lib/features/voice_call/presentation/active_call_screen.dart` |
| `Routes.callComplete` | `CallCompleteScreen` | `lib/features/feedback/presentation/call_complete_screen.dart` |

`Routes.home`은 `ShellScreen`으로 연결되며, 실제 caller/scenario/delay 선택 UI는 별도 화면이 아니라 그 안의 `HomeTab` 한 화면에 모두 들어있다 (docs/HOME_V2.md 개편 이후). 선택 상태는 전부 `callSetupProvider`에서 읽고 쓴다. `IncomingCallScreen`/`ActiveCallScreen`/`CallCompleteScreen`은 인자 없는 생성자(`const XxxScreen({super.key})`).

## 테마 (AppTheme)
- `lib/core/theme/app_theme.dart` — `AppTheme.dark`는 `AppTheme.light`의 별칭이며 실제로는 라이트 전용 (docs/DESIGN_V3.md 파스텔 리디자인 이후).
- 색(`AppColors`): 배경 `#F6F4FE`, 표면 `#FFFFFF`, 강조(accent) `#8B7CF6`, 보조 강조 `#7C9BF8`, glow `#C4B5FD`, 위험 `#F87171`(거절/종료), 텍스트 주 `#3E3A5F`, 보조 `#9A94B8`
- 라벤더-화이트 배경 + 부드러운 그라디언트 오브(SoftOrb) 마스코트 + 필(pill) 형태 칩. 다크 네온/글로우 느낌 금지, 친근하고 부드러운 톤.

## 내비게이션 플로우
`Routes.home`(`ShellScreen`)의 홈 탭(`HomeTab`)에서 caller/scenario 프리셋 칩과 delay 바텀시트로 `callSetupProvider`를 채운 뒤, 통화 버튼 탭 시 `context.go(Routes.incomingCall)`로 직행한다 (별도의 caller/scenario/delay 선택 화면 없음).
- `IncomingCallScreen`이 내부에서 delay만큼 대기(카운트다운 "N초 후 전화가 옵니다" 표시) 후 수신 UI + 벨소리/진동 시작.
- 응답 → `context.go(Routes.activeCall)`, 거절/대기 중 취소 → 벨소리 정지(대기 중이면 생략) 후 `reset()` + `context.go(Routes.home)`.
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
