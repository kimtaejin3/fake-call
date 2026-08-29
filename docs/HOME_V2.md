# 홈 개편 v2 — 앱형 메인 + 하단 네비게이션

## 목표
퍼널(홈→Caller→Scenario→Delay 페이지 이동) 제거. 첫 화면부터 "앱다운" 메인:
하단 네비게이션 바(홈/기록/설정) + 홈 탭 한 화면에서 모든 선택 후 바로 실행.

## 구조
- `Routes.home('/')` → `ShellScreen` (lib/features/shell/presentation/shell_screen.dart)
  - IndexedStack + BottomNavigationBar(또는 NavigationBar) 3탭: 홈 / 기록 / 설정
  - 탭 아이콘: Icons.phone_in_talk(홈), Icons.history(기록), Icons.settings(설정). 스타일: surface 배경, 선택 accent, 미선택 textSecondary, 상단 1px surfaceBorder.
- 수신/통화/완료 화면은 기존 라우트 그대로 전체화면 (셸 밖).
- 기존 caller/scenario/delay 선택 화면 파일과 라우트는 남겨두되 홈에서 더 이상 사용 안 함.

## 홈 탭 (lib/features/home/presentation/home_tab.dart — HomeScreen 대체, 클래스명 HomeTab)
스크롤 가능한 한 화면 구성:
1. 상단: 인사말 소제목("곤란한 순간, 자연스럽게") + 작은 GlowOrb(크지 않게, size 120~140) 히어로.
2. "누가 전화할까요?" 섹션 — kCallers를 가로 스크롤 원형 아바타(CallerAvatar) 칩으로. 선택 시 accent 테두리+글로우.
3. "왜 전화했나요?" 섹션 — kScenarios 세로 카드 리스트(컴팩트, 높이 56 내외). 선택 시 accent 테두리.
4. "언제 전화할까요?" 섹션 — kDelayOptions 가로 칩(ChoiceChip 스타일 커스텀).
5. 하단 고정(또는 리스트 마지막) 그라데이션 CTA "전화 받기" → callSetup 완료 상태로 `context.go(Routes.incomingCall)`.
- 초기 기본값: 엄마 / come_home / 30초 후 를 미리 선택해 두어 원탭 실행 가능(PRD 32절 Quick Call 정신).
- 상태는 기존 callSetupProvider 그대로 사용 (selectCaller/selectScenario/selectDelay).

## 기록 탭 (lib/features/history/)
- `application/call_history_provider.dart`: `CallRecord { callerName, scenarioTitle, endedAt(DateTime), durationSeconds, feedback(String?) }` + `callHistoryProvider` (NotifierProvider<List<CallRecord>>, `add(record)`, 최신순). MVP는 메모리 보관(영속화 X).
- `presentation/history_tab.dart`: 기록 리스트(CallerAvatar 작게 + 이름/시나리오, 시간 "HH:mm", 통화시간 "32초"). 비어 있으면 GlowOrb 작은 것 + "아직 통화 기록이 없어요" 빈 상태.
- 기록 추가 시점: CallComplete 화면 `_finish()`에서 callHistoryProvider에 add (durationSeconds는 활성통화에서 전달이 어려우면 MVP로 0 또는 생략 가능 — 가능하면 ActiveCall이 종료 시점에 elapsed를 어딘가(간단한 StateProvider<int> lastCallDurationProvider)로 남기고 complete에서 읽기).

## 설정 탭 (lib/features/settings/presentation/settings_tab.dart)
MVP 정적 리스트 (surface 카드 그룹):
- "벨소리" (기본), "AI 음성" (기본), 항목 탭 시 아직 준비 중 SnackBar
- "앱 정보" — 버전 1.0.0
과하지 않게, 리스트 타일 스타일은 기존 카드와 통일.

## 테스트
flow_test.dart 갱신 필요: 새 플로우 = 홈 탭에서 (기본 선택 유지 또는 명시 탭) → '전화 받기' 탭 → 이후 기존과 동일(수신→통화→완료→홈). 완료 후 홈 복귀 시 하단 네비게이션 존재 확인.
